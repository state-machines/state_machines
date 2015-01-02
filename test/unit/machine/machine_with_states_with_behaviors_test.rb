require_relative '../../test_helper'

class MachineWithStatesWithBehaviorsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)

    @parked, @idling = @machine.state :parked, :idling do
      def speed
        0
      end
    end
  end

  def test_should_define_behaviors_for_each_state
    refute_nil @parked.context_methods[:speed]
    refute_nil @idling.context_methods[:speed]
  end

  def test_should_define_different_behaviors_for_each_state
    refute_equal @parked.context_methods[:speed], @idling.context_methods[:speed]
  end
end
