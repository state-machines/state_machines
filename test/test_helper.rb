require 'state_machines'
require 'minitest/autorun'
begin
  require 'pry-byebug'
rescue LoadError
end
require 'minitest/reporters'
Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new]

class StateMachinesTest < MiniTest::Test
  def before_setup
    super
    StateMachines::Integrations.reset
  end
end
