# frozen_string_literal: true

source 'https://rubygems.org'
gemspec

platform :mri do
  gem 'debug'
end

gem 'minitest-reporters'
gem 'rubocop', require: false
gem 'rubocop-minitest', require: false

gem 'rubocop-rake', require: false

# Async support dependencies (MRI Ruby only)
# These gems are required for StateMachines::AsyncMode functionality
# and are loaded conditionally based on Ruby engine compatibility
platform :ruby do
  gem 'async', require: false
  gem 'concurrent-ruby', require: false
end
