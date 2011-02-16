# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "flipstone-deployment/version"

Gem::Specification.new do |s|
  s.name        = "flipstone-deployment"
  s.version     = Flipstone::Deployment::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Scott Conely, David Vollbracht"]
  s.email       = ["scott@flipstone.com, david@flipstone.com"]
  s.homepage    = "http://github.com/flipstone/flipstone-deployment"
  s.summary     = %q{Common deployment recipes for Flipstone projects.}
  s.description = %q{}

  s.rubyforge_project = "flipstone-deployment"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
