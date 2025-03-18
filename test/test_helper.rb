require 'state_machines'
require 'minitest/autorun'
begin
  require 'debug'
rescue LoadError
end
require 'minitest/reporters'
Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new]

class StateMachinesTest < Minitest::Test
  def before_setup
    super
    StateMachines::Integrations.reset
  end
end
