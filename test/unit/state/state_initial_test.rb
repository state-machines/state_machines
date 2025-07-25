# frozen_string_literal: true

require 'test_helper'

class StateInitialTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @machine.states << @state = StateMachines::State.new(@machine, :parked, initial: true)
  end

  def test_should_be_initial
    assert @state.initial
    assert_predicate @state, :initial?
  end
end
