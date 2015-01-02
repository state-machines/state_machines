require_relative '../../test_helper'

class StateWithConflictingHelpersAfterDefinitionTest < StateMachinesTest
  def setup
    @original_stderr, $stderr = $stderr, StringIO.new

    @klass = Class.new do
      def parked?
        0
      end
    end
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked
    @object = @klass.new
  end

  def test_should_not_override_state_predicate
    assert_equal 0, @object.parked?
  end

  def test_should_still_allow_super_chaining
    @klass.class_eval do
      def parked?
        super
      end
    end

    assert_equal false, @object.parked?
  end

  def test_should_not_output_warning
    assert_equal '', $stderr.string
  end

  def teardown
    $stderr = @original_stderr
  end
end
