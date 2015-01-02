require_relative '../../test_helper'

class StateWithValidMethodCallForDifferentStateTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @ancestors = @klass.ancestors
    @machine.states << @state = StateMachines::State.new(@machine, :idling)
    @state.context do
      def speed
        0
      end
    end

    @object = @klass.new
  end

  def test_should_call_method_missing_arg
    assert_equal 1, @state.call(@object, :speed, method_missing: lambda { 1 })
  end

  def test_should_raise_invalid_context_on_no_method_error
    exception = assert_raises(StateMachines::InvalidContext) do
      @state.call(@object, :speed, method_missing: lambda { fail NoMethodError.new('Invalid', :speed, []) })
    end
    assert_equal @object, exception.object
    assert_equal 'State nil for :state is not a valid context for calling #speed', exception.message
  end

  def test_should_raise_original_error_on_no_method_error_with_different_arguments
    assert_raises(NoMethodError) do
      @state.call(@object, :speed, method_missing: lambda { fail NoMethodError.new('Invalid', :speed, [1]) })
    end
  end

  def test_should_raise_original_error_on_no_method_error_for_different_method
    assert_raises(NoMethodError) do
      @state.call(@object, :speed, method_missing: lambda { fail NoMethodError.new('Invalid', :rpm, []) })
    end
  end
end
