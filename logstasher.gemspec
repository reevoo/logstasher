# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "logstasher/version"

Gem::Specification.new do |s|
  s.name        = "rv-logstasher"
  s.version     = LogStasher::VERSION
  s.authors     = ['David Sevcik', 'Alex Malkov']
  s.email       = ['david.sevcik@reevoo.com', 'alex.malkov@reevoo.com']
  s.homepage    = "https://github.com/reevoo/logstasher"
  s.summary     = %q{Produces log in the logstash format}
  s.description = %q{Produces log in the logstash format}
  s.license     = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "logstash-event", "~> 1.2"

  s.add_development_dependency "redis"
  s.add_development_dependency "rspec"
  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "pry"
end
