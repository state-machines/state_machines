# -*- encoding: utf-8 -*-
# stub: minitest-reporters 1.7.1 ruby lib

Gem::Specification.new do |s|
  s.name = "minitest-reporters".freeze
  s.version = "1.7.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Alexander Kern".freeze]
  s.date = "2024-06-20"
  s.description = "Death to haphazard monkey-patching! Extend Minitest through simple hooks.".freeze
  s.email = ["alex@kernul.com".freeze]
  s.homepage = "https://github.com/minitest-reporters/minitest-reporters".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Create customizable Minitest output formats".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<minitest>.freeze, [">= 5.0"])
  s.add_runtime_dependency(%q<ansi>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<ruby-progressbar>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<builder>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0"])
end
