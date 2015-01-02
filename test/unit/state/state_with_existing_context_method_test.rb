require_relative '../../test_helper'

class StateWithExistingContextMethodTest < StateMachinesTest
  def setup
    @klass = Class.new do
      def speed
        60
      end
    end
    @original_speed_method = @klass.instance_method(:speed)

    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, :idling)
    @state.context do
      def speed
        0
      end
    end
  end

  def test_should_not_override_method
    assert_equal @original_speed_method, @klass.instance_method(:speed)
  end
end
