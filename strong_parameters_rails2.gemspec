$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "strong_parameters/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "strong_parameters_rails2"
  s.version     = StrongParameters::VERSION
  s.authors     = ["Michael Grosser", "David Heinemeier Hansson"]
  s.email       = ["michael@grosser.it"]
  s.summary     = "Permitted and required parameters for Action Pack"
  s.license     = "MIT"
  s.homepage    = "https://github.com/grosser/strong_parameters/tree/rails2"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "actionpack", "~> 2.3"
  s.add_dependency "activerecord", "~> 2.3"

  s.add_development_dependency "bump"
  s.add_development_dependency "rake"
  s.add_development_dependency "mocha"
  s.add_development_dependency "sqlite3"
end
