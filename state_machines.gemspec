# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'state_machines/version'

Gem::Specification.new do |spec|
  spec.name          = 'state_machines'
  spec.version       = StateMachines::VERSION
  spec.authors       = ['Abdelkader Boudih', 'Aaron Pfeifer']
  spec.email         = ['terminale@gmail.com']
  spec.summary       = %q(State machines for attributes)
  spec.description   = %q(Adds support for creating state machines for attributes on any Ruby class)
  spec.homepage      = 'https://github.com/seuros/state_machines'
  spec.license       = 'MIT'

  spec.required_ruby_version     = '>= 1.9.3'
  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(/^spec\//)
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec' , '3.0.0.beta2'
  spec.add_development_dependency 'rspec-its'
end
