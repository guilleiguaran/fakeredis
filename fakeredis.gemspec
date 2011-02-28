# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "fakeredis/version"

Gem::Specification.new do |s|
  s.name        = "fakeredis"
  s.version     = FakeRedis::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["fakeredis"]
  s.email       = ["guilleiguaran@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Fake redis-rb for your tests}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "fakeredis"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency(%q<rspec>, [">= 2.0.0"])
end
