# frozen_string_literal: true

require_relative 'lib/state_machines/version'

Gem::Specification.new do |spec|
  spec.name          = 'state_machines'
  spec.version       = StateMachines::VERSION
  spec.authors       = ['Abdelkader Boudih', 'Aaron Pfeifer']
  spec.email         = %w(terminale@gmail.com aaron@pluginaweek.org)
  spec.summary       = %q(State machines for attributes)
  spec.description   = %q(Adds support for creating state machines for attributes on any Ruby class)
  spec.homepage      = 'https://github.com/state-machines/state_machines'
  spec.license       = 'MIT'

  spec.metadata["changelog_uri"] = 'https://github.com/state-machines/state_machines/blob/master/CHANGELOG.md'
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.required_ruby_version     = '>= 3.0.0'
  spec.files         = Dir.glob('{lib}/**/*') + %w(LICENSE.txt README.md)
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 1.7.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest', '>= 5.4'
end
