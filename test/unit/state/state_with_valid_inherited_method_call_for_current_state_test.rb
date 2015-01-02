require_relative '../../test_helper'

class StateWithValidInheritedMethodCallForCurrentStateTest < StateMachinesTest
  def setup
    @superclass = Class.new do
      def speed(arg = nil)
        [arg]
      end
    end
    @klass = Class.new(@superclass)
    @machine = StateMachines::Machine.new(@klass, initial: :idling)
    @ancestors = @klass.ancestors
    @state = @machine.state(:idling)
    @state.context do
      def speed(arg = nil)
        [arg] + super(2)
      end
    end

    @object = @klass.new
  end

  def test_should_not_raise_an_exception
    @state.call(@object, :speed, method_missing: lambda { fail })
  end

  def test_should_be_able_to_call_super
    assert_equal [1, 2], @state.call(@object, :speed, 1)
  end

  def test_should_allow_redefinition
    @state.context do
      def speed(arg = nil)
        [arg] + super(3)
      end
    end

    assert_equal [1, 3], @state.call(@object, :speed, 1)
  end
end
