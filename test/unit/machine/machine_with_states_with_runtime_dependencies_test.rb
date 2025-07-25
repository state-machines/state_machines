# frozen_string_literal: true

require 'test_helper'

class MachineWithStatesWithRuntimeDependenciesTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked
  end

  def test_should_not_evaluate_value_during_definition
    @machine.state :parked, value: ->  { raise ArgumentError }
  end

  def test_should_not_evaluate_if_not_initial_state
    @machine.state :parked, value: ->  { raise ArgumentError }
    @klass.new
  end
end
