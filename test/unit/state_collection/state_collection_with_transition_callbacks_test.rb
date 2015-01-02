require_relative '../../test_helper'

class StateCollectionWithTransitionCallbacksTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @states = StateMachines::StateCollection.new(@machine)

    @states << @parked = StateMachines::State.new(@machine, :parked)
    @states << @idling = StateMachines::State.new(@machine, :idling)
    @machine.states.concat(@states)

    @machine.before_transition to: :idling, do: lambda {}
  end

  def test_should_order_states_after_initial_state
    @parked.initial = true
    assert_equal [@parked, @idling], @states.by_priority
  end

  def test_should_order_states_after_transition_states
    @machine.event :ignite do
      transition from: :parked
    end
    assert_equal [@parked, @idling], @states.by_priority
  end

  def test_should_order_states_after_states_with_behaviors
    @parked.context do
      def speed
        0
      end
    end
    assert_equal [@parked, @idling], @states.by_priority
  end

  def test_should_order_states_after_other_states
    assert_equal [@parked, @idling], @states.by_priority
  end
end

