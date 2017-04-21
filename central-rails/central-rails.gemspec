$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "central/rails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "central-rails"
  s.version     = Central::Rails::VERSION
  s.authors     = ["zerosign"]
  s.email       = ["r1nlx0@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Central::Rails."
  s.description = "TODO: Description of Central::Rails."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0.2"

  s.add_development_dependency "sqlite3"
end
