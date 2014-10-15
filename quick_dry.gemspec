$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "quick_dry/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "quick_dry"
  s.version     = QuickDry::VERSION
  s.authors     = ["Nathan Hanna"]
  s.email       = ["jnathanhdev@gmail.com"]
  s.homepage    = "https://github.com/jnathanh/quick_dry"
  s.summary     = "Implements a DRY front end for Ruby on Rails: routes, controllers, and views"
  s.description = "Implements a DRY front end for Ruby on Rails: routes, controllers, and views..."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0"
  s.add_dependency "jquery-rails", "~> 3"
  s.add_dependency "jquery-ui-rails"

  s.add_development_dependency "sqlite3"
end
