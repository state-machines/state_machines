require_relative '../../test_helper'

class StateNotFinalTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @machine.states << @state = StateMachines::State.new(@machine, :parked)
  end

  def test_should_not_be_final_with_outgoing_whitelist_transitions
    @machine.event :ignite do
      transition parked: :idling
    end

    refute @state.final?
  end

  def test_should_not_be_final_with_outgoing_all_transitions
    @machine.event :ignite do
      transition all => :idling
    end

    refute @state.final?
  end

  def test_should_not_be_final_with_outgoing_blacklist_transitions
    @machine.event :ignite do
      transition all - :first_gear => :idling
    end

    refute @state.final?
  end
end
