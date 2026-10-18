# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'shellwords'

Rake::TestTask.new(:functional) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/functional/*_test.rb']
end

Rake::TestTask.new(:unit) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/unit/**/*_test.rb']
end

desc 'Run the full Minitest suite directly (no padded_cell).'
task minitest: %i[unit functional]

desc 'Run the test suite (padded_cell on CRuby, plain Minitest elsewhere)'
if RUBY_ENGINE == 'ruby'
  task :test do
    sh 'padded_cell', *Shellwords.split(ENV.fetch('TESTOPTS', ''))
  end
else
  task test: :minitest
end

task default: :test

desc 'Update COSS version to match current gem version'
task :update_coss_version do
  sh 'scripts/update_coss_version.sh'
end
