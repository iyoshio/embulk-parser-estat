require "jsonpath"

module Embulk
  module Parser

    class Estat < ParserPlugin
      Plugin.register_parser("estat", self)

      def self.transaction(config, &control)
        # configuration code:
        task = {
          :master      => config.param("master", :hash),
          :transaction => config.param("transaction", :hash),
          :map         => config.param("map", :array),
        }

        master_hash = {}
        task[:master]["columns"].each do |c|
          master_hash[ c["name"] ] = c
        end

        index = 0
        columns = []
        task[:transaction]["columns"].each_with_index.map do |c, i|

          columns << Column.new(index, c["name"], c["type"].to_sym)
          index += 1

          task[:map].each do |m| 

            if m["transaction_key"] == c["name"]
              
              m["append"].each do |a|
                columns << Column.new(index, c["name"] + "_" + a, master_hash[ a ]["type"].to_sym)
                index += 1
              end

            end

          end

        end

        yield(task, columns)
      end

      def init
        # initialization code:
        @option1 = task["option1"]
        @option2 = task["option2"]
        @option3 = task["option3"]
      end

      def run(file_input)

        while file = file_input.next_file
          content = file.read
          master = make_master( parse_records(content, @task[:master]).flatten, @task[:map])
          map_records(content, @task[:transaction], @page_builder, master)
        end
        @page_builder.finish
      end

      def make_master(records, map)

        master = {}
        records.each do |r|
          map.each do |m| 
            t = m["transaction_key"]
            key   = r[ m["master_key"] ]
            value = r[ m["master_value"] ]

            master[ t ] = { "default": m["append"].map {|a| "" }, "map": {} } unless master.has_key?( t )

            if key == t
              master[ t ][:map][ value ] = {} unless master[ t ][:map].has_key?( value )
              master[ t ][:map][ value ] = m["append"].map {|a| r[a] }
            end

          end
        end

        master
      end
     

      def map_records(content, task, page, master)
        schema   = task["columns"]
        rootPath = JsonPath.new(task["root"])
        records = []
        rootPath.on(content).flatten.each do |e|
          make_records(schema, e, task).each do |ee|
            page.add( map(ee, master) )
          end
        end

      end

      def map(records, master)
        mapped = []
        records.each do |k,v|
          mapped << v
          if master.has_key?(k)
            if master[k][:map].has_key?(v)
              mapped << master[k][:map][ v ]
            else
              mapped << master[k][:default]
            end
          end
        end
        mapped.flatten!
      end

      def parse_records(content, task, page = nil, master = nil)
        schema   = task["columns"]
        rootPath = JsonPath.new(task["root"])
        records = []
        rootPath.on(content).flatten.each do |e|
          records << make_records(schema, e, task).flatten
        end
        records
      end

      def make_records(schema, e, task)
        records = []
        unless task["sub"].nil? then
          excluded = e.select {|k,v| k != task["sub"]}
          excluded = excluded.map { |k,v| [ "$." + k, v ] }.to_h
          JsonPath.on(e, task["sub"]).flatten.each do |sub_e|
            sub_e.merge!( excluded )
            records << make_record(schema, sub_e)
          end 
        else
          records << make_record(schema, e)
        end
        records
      end

      def make_record(schema, e)
        record = {} 
        schema.map do |c| 
          name = c["name"]
          path = c["path"]
          
          val = path.nil? ? e[name] : e[path]
          val = find_by_path(e, path) if val.nil?

          v = val.nil? ? "" : val
          type = c["type"]
          case type
            when "string"
              v
            when "long"
              v.to_i
            when "double"
              v.to_f
            when "boolean"
              ["yes", "true", "1"].include?(v.downcase)
            when "timestamp"
              v.empty? ? nil : Time.strptime(v, c["format"])
            else
              raise "Unsupported type #{type}"
          end
          record[ name ] = v
        end
        record
      end

      def find_by_path(e, path)
        JsonPath.on(e, path).first
      end

    end

  end
end
