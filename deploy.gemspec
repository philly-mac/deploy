# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "deploy/version"
require "date"

Gem::Specification.new do |s|
  s.name        = "deploy"
  s.version     = Deploy::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Philip MacIver", "Ali Jelveh"]
  s.email       = ["philip@ivercore.com"]
  s.homepage    = "http://github.com/philly-mac/deploy"
  s.summary     = %q{Deployment made more plain}
  s.description = %q{Deployment made more plain}
  s.date    = Date.today.to_s

  s.rubyforge_project = "deploy"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

