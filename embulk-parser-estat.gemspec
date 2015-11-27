
Gem::Specification.new do |spec|
  spec.name          = "embulk-parser-estat"
  spec.version       = "0.9.0"
  spec.authors       = ["Yoshio Ikai"]
  spec.summary       = "e-stat parser plugin for Embulk"
  spec.description   = "Parses e-stat files read by other file input plugins."
  spec.email         = ["yoshio.ikai@dentsu.co.jp"]
  spec.licenses      = ["MIT"]
  # TODO set this: spec.homepage      = "https://github.com/YOUR_NAME/embulk-parser-estat"

  spec.files         = `git ls-files`.split("\n") + Dir["classpath/*.jar"]
  spec.test_files    = spec.files.grep(%r{^(test|spec)/})
  spec.require_paths = ["lib"]

  #spec.add_dependency 'YOUR_GEM_DEPENDENCY', ['~> YOUR_GEM_DEPENDENCY_VERSION']
  spec.add_development_dependency 'embulk', ['~> 0.7.7']
  spec.add_development_dependency 'bundler', ['~> 1.0']
  spec.add_development_dependency 'rake', ['>= 10.0']
  spec.add_development_dependency 'jsonpath', [ '~> 0.5' ]
end
