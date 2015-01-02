require_relative '../../test_helper'

class MachineWithStatesTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @parked, @idling = @machine.state :parked, :idling

    @object = @klass.new
  end

  def test_should_have_states
    assert_equal [nil, :parked, :idling], @machine.states.map { |state| state.name }
  end

  def test_should_allow_state_lookup_by_name
    assert_equal @parked, @machine.states[:parked]
  end

  def test_should_allow_state_lookup_by_value
    assert_equal @parked, @machine.states['parked', :value]
  end

  def test_should_allow_human_state_name_lookup
    assert_equal 'parked', @klass.human_state_name(:parked)
  end

  def test_should_raise_exception_on_invalid_human_state_name_lookup
    exception = assert_raises(IndexError) { @klass.human_state_name(:invalid) }
    assert_equal ':invalid is an invalid name', exception.message
  end

  def test_should_use_stringified_name_for_value
    assert_equal 'parked', @parked.value
  end

  def test_should_not_use_custom_matcher
    assert_nil @parked.matcher
  end

  def test_should_raise_exception_if_invalid_option_specified
    exception = assert_raises(ArgumentError) { @machine.state(:first_gear, invalid: true) }
    assert_equal 'Unknown key: :invalid. Valid keys are: :value, :cache, :if, :human_name', exception.message
  end

  def test_should_raise_exception_if_conflicting_type_used_for_name
    exception = assert_raises(ArgumentError) { @machine.state 'first_gear' }
    assert_equal '"first_gear" state defined as String, :parked defined as Symbol; all states must be consistent', exception.message
  end

  def test_should_not_raise_exception_if_conflicting_type_is_nil_for_name
    @machine.state nil
  end
end

