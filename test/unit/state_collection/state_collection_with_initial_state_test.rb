# frozen_string_literal: true

require 'test_helper'

class StateCollectionWithInitialStateTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @states = StateMachines::StateCollection.new(@machine)

    @states << @parked = StateMachines::State.new(@machine, :parked)
    @states << @idling = StateMachines::State.new(@machine, :idling)
    @machine.states.concat(@states)

    @parked.initial = true
  end

  def test_should_order_state_before_transition_states
    @machine.event :ignite do
      transition to: :idling
    end

    assert_equal [@parked, @idling], @states.by_priority
  end

  def test_should_order_state_before_states_with_behaviors
    @idling.context do
      def speed
        0
      end
    end

    assert_equal [@parked, @idling], @states.by_priority
  end

  def test_should_order_state_before_other_states
    assert_equal [@parked, @idling], @states.by_priority
  end

  def test_should_order_state_before_callback_states
    @machine.before_transition from: :idling, do: -> {}

    assert_equal [@parked, @idling], @states.by_priority
  end

  def test_should_have_correct_states
    assert_sm_states_list(@machine, %i[parked idling])
  end

  def test_should_have_correct_initial_state
    assert_sm_initial_state(@machine, :parked)
  end
end
