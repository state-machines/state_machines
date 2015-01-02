require_relative '../../test_helper'

class StateAfterBeingCopiedTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @machine.states << @state = StateMachines::State.new(@machine, :parked)
    @copied_state = @state.dup
  end

  def test_should_not_have_the_context
    state_context = nil
    @state.context { state_context = self }

    copied_state_context = nil
    @copied_state.context { copied_state_context = self }

    refute_same state_context, copied_state_context
  end
end
