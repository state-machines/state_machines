require_relative '../../test_helper'

class StateWithCachedLambdaValueTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @dynamic_value = -> { 'value' }
    @machine.states << @state = StateMachines::State.new(@machine, :parked, value: @dynamic_value, cache: true)
  end

  def test_should_be_caching
    assert @state.cache
  end

  def test_should_evaluate_value
    assert_equal 'value', @state.value
  end

  def test_should_only_evaluate_value_once
    value = @state.value
    assert_same value, @state.value
  end

  def test_should_update_value_index_for_state_collection
    @state.value
    assert_equal @state, @machine.states['value', :value]
    assert_nil @machine.states[@dynamic_value, :value]
  end
end
