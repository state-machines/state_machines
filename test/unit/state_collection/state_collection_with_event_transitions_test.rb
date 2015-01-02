require_relative '../../test_helper'

class StateCollectionWithEventTransitionsTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @states = StateMachines::StateCollection.new(@machine)

    @states << @parked = StateMachines::State.new(@machine, :parked)
    @states << @idling = StateMachines::State.new(@machine, :idling)
    @machine.states.concat(@states)

    @machine.event :ignite do
      transition to: :idling
    end
  end

  def test_should_order_states_after_initial_state
    @parked.initial = true
    assert_equal [@parked, @idling], @states.by_priority
  end

  def test_should_order_states_before_states_with_behaviors
    @parked.context do
      def speed
        0
      end
    end
    assert_equal [@idling, @parked], @states.by_priority
  end

  def test_should_order_states_before_other_states
    assert_equal [@idling, @parked], @states.by_priority
  end

  def test_should_order_state_before_callback_states
    @machine.before_transition from: :parked, do: lambda {}
    assert_equal [@idling, @parked], @states.by_priority
  end
end
