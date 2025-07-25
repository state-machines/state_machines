# frozen_string_literal: true

require 'test_helper'

class StateNotInitialTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @machine.states << @state = StateMachines::State.new(@machine, :parked, initial: false)
  end

  def test_should_not_be_initial
    refute @state.initial
    refute_predicate @state, :initial?
  end
end
