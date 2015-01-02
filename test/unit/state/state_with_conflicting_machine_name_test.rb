require_relative '../../test_helper'
require 'stringio'

class StateWithConflictingMachineNameTest < StateMachinesTest
  def setup
    @original_stderr, $stderr = $stderr, StringIO.new

    @klass = Class.new
    @state_machine = StateMachines::Machine.new(@klass, :state)
  end

  def test_should_output_warning_if_name_conflicts
    StateMachines::State.new(@state_machine, :state)
    assert_equal "Instance method \"state?\" is already defined in #{@klass} :state instance helpers, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string
  end

  def teardown
    $stderr = @original_stderr
  end
end
