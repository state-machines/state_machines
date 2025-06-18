# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
Rake::TestTask.new(:functional) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/functional/*_test.rb']
end

Rake::TestTask.new(:unit) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/unit/**/*_test.rb']
end

desc 'Default: run all tests.'
task test: %i[unit functional]
task default: :test

desc 'Update COSS version to match current gem version'
task :update_coss_version do
  sh 'scripts/update_coss_version.sh'
end
