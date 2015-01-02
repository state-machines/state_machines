require_relative '../../test_helper'

class StateFinalTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @machine.states << @state = StateMachines::State.new(@machine, :parked)
  end

  def test_should_be_final_without_input_transitions
    assert @state.final?
  end

  def test_should_be_final_with_input_transitions
    @machine.event :park do
      transition idling: :parked
    end

    assert @state.final?
  end

  def test_should_be_final_with_loopback
    @machine.event :ignite do
      transition parked: same
    end

    assert @state.final?
  end
end
