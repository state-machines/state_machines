# frozen_string_literal: true

require 'test_helper'

class StateWithoutCachedLambdaValueTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @dynamic_value = -> { 'value'.dup }
    @machine.states << @state = StateMachines::State.new(@machine, :parked, value: @dynamic_value)
  end

  def test_should_not_be_caching
    refute @state.cache
  end

  def test_should_evaluate_value_each_time
    value1 = @state.value
    value2 = @state.value

    refute_same value1, value2
  end

  def test_should_not_update_value_index_for_state_collection
    @state.value

    assert_nil @machine.states['value', :value]
    assert_equal @state, @machine.states[@dynamic_value, :value]
  end
end
