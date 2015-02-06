require_relative '../../test_helper'

class MachineCollectionStateInitializationTest < StateMachinesTest
  def setup
    @machines = StateMachines::MachineCollection.new

    @klass = Class.new

    @machines[:state] = StateMachines::Machine.new(@klass, :state, initial: :parked)
    @machines[:alarm_state] = StateMachines::Machine.new(@klass, :alarm_state, initial: ->(_object) { :active })
    @machines[:alarm_state].state :active, value: -> { 'active' }

    # Prevent the auto-initialization hook from firing
    @klass.class_eval do
      def initialize
      end
    end

    @object = @klass.new
    @object.state = nil
    @object.alarm_state = nil
  end

  def test_should_raise_exception_if_invalid_option_specified
    assert_raises(ArgumentError) { @machines.initialize_states(@object, invalid: true) }
  end

  def test_should_initialize_static_states_after_block
    @machines.initialize_states(@object) do
      @state_in_block = @object.state
      @alarm_state_in_block = @object.alarm_state
    end

    assert_nil @state_in_block
    assert_nil @alarm_state_in_block
  end

  def test_should_initialize_dynamic_states_after_block
    @machines.initialize_states(@object) do
      @alarm_state_in_block = @object.alarm_state
    end

    assert_nil @alarm_state_in_block
    assert_equal 'active', @object.alarm_state
  end

  def test_should_initialize_all_states_without_block
    @machines.initialize_states(@object)

    assert_equal 'parked', @object.state
    assert_equal 'active', @object.alarm_state
  end

  def test_should_skip_static_states_if_disabled
    @machines.initialize_states(@object, static: false)
    assert_nil @object.state
    assert_equal 'active', @object.alarm_state
  end

  def test_should_initialize_existing_static_states_by_default
    @object.state = 'idling'
    @machines.initialize_states(@object)
    assert_equal 'parked', @object.state
  end

  def test_should_initialize_existing_static_states_if_forced
    @object.state = 'idling'
    @machines.initialize_states(@object, static: :force)
    assert_equal 'parked', @object.state
  end

  def test_should_initialize_existing_static_states_if_not_forced
    @object.state = 'idling'
    @machines.initialize_states(@object, static: true)
    assert_equal 'parked', @object.state
  end

  def test_should_skip_dynamic_states_if_disabled
    @machines.initialize_states(@object, dynamic: false)
    assert_equal 'parked', @object.state
    assert_nil @object.alarm_state
  end

  def test_should_not_initialize_existing_dynamic_states_by_default
    @object.alarm_state = 'inactive'
    @machines.initialize_states(@object)
    assert_equal 'inactive', @object.alarm_state
  end

  def test_should_initialize_existing_dynamic_states_if_forced
    @object.alarm_state = 'inactive'
    @machines.initialize_states(@object, dynamic: :force)
    assert_equal 'active', @object.alarm_state
  end

  def test_should_not_initialize_existing_dynamic_states_if_not_forced
    @object.alarm_state = 'inactive'
    @machines.initialize_states(@object, dynamic: true)
    assert_equal 'inactive', @object.alarm_state
  end

  def test_shouldnt_force_state_given_either_as_string_or_symbol
    @object.state = 'notparked'

    @machines.initialize_states(@object, {}, { state: "parked" })
    assert_equal 'notparked', @object.state

    @machines.initialize_states(@object, {}, { "state" => "parked" })
    assert_equal 'notparked', @object.state
  end
end
