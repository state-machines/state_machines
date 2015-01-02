require_relative '../../test_helper'

class MachineStateInitializationTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, :state, initial: :parked, initialize: false)

    @object = @klass.new
    @object.state = nil
  end

  def test_should_set_states_if_nil
    @machine.initialize_state(@object)

    assert_equal 'parked', @object.state
  end

  def test_should_set_states_if_empty
    @object.state = ''
    @machine.initialize_state(@object)

    assert_equal 'parked', @object.state
  end

  def test_should_not_set_states_if_not_empty
    @object.state = 'idling'
    @machine.initialize_state(@object)

    assert_equal 'idling', @object.state
  end

  def test_should_set_states_if_not_empty_and_forced
    @object.state = 'idling'
    @machine.initialize_state(@object, force: true)

    assert_equal 'parked', @object.state
  end

  def test_should_not_set_state_if_nil_and_nil_is_valid_state
    @machine.state :initial, value: nil
    @machine.initialize_state(@object)

    assert_nil @object.state
  end

  def test_should_write_to_hash_if_specified
    @machine.initialize_state(@object, to: hash = {})
    assert_equal({ 'state' => 'parked' }, hash)
  end

  def test_should_not_write_to_object_if_writing_to_hash
    @machine.initialize_state(@object, to: {})
    assert_nil @object.state
  end
end

