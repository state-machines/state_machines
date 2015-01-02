require_relative '../../test_helper'

class StateWithConflictingHelpersBeforeDefinitionTest < StateMachinesTest
  def setup
    @original_stderr, $stderr = $stderr, StringIO.new

    @superclass = Class.new do
      def parked?
        0
      end
    end
    @klass = Class.new(@superclass)
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked
    @object = @klass.new
  end

  def test_should_not_override_state_predicate
    assert_equal 0, @object.parked?
  end

  def test_should_output_warning
    assert_equal "Instance method \"parked?\" is already defined in #{@superclass}, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string
  end

  def teardown
    $stderr = @original_stderr
  end
end
