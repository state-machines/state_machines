require_relative '../../test_helper'

class StateWithValidMethodCallForCurrentStateTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :idling)
    @ancestors = @klass.ancestors
    @state = @machine.state(:idling)
    @state.context do
      def speed(arg = nil)
        block_given? ? [arg, yield] : arg
      end
    end

    @object = @klass.new
  end

  def test_should_not_raise_an_exception
    @state.call(@object, :speed, method_missing: lambda { fail })
  end

  def test_should_pass_arguments_through
    assert_equal 1, @state.call(@object, :speed, 1, method_missing: lambda {})
  end

  def test_should_pass_blocks_through
    assert_equal [nil, 1], @state.call(@object, :speed) { 1 }
  end

  def test_should_pass_both_arguments_and_blocks_through
    assert_equal [1, 2], @state.call(@object, :speed, 1, method_missing: lambda {}) { 2 }
  end
end
