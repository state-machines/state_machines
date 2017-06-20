lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'state_machines/version'

Gem::Specification.new do |spec|
  spec.name          = 'state_machines'
  spec.version       = StateMachines::VERSION
  spec.authors       = ['Abdelkader Boudih', 'Aaron Pfeifer']
  spec.email         = %w(terminale@gmail.com aaron@pluginaweek.org)
  spec.summary       = %q(State machines for attributes)
  spec.description   = %q(Adds support for creating state machines for attributes on any Ruby class)
  spec.homepage      = 'https://github.com/state-machines/state_machines'
  spec.license       = 'MIT'

  spec.required_ruby_version     = '>= 2.0.0'
  spec.files         = `git ls-files -z`.split("\x0")
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 1.7.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest', '>= 5.4'
end
