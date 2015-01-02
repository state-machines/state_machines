require_relative '../../test_helper'

class MachineCollectionFireTest < StateMachinesTest
  def setup
    @machines = StateMachines::MachineCollection.new

    @klass = Class.new do
      attr_reader :saved

      def save
        @saved = true
      end
    end

    # First machine
    @machines[:state] = @state = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
    @state.event :ignite do
      transition parked: :idling
    end
    @state.event :park do
      transition idling: :parked
    end

    # Second machine
    @machines[:alarm_state] = @alarm_state = StateMachines::Machine.new(@klass, :alarm_state, initial: :active, action: :save, namespace: 'alarm')
    @alarm_state.event :enable do
      transition off: :active
    end
    @alarm_state.event :disable do
      transition active: :off
    end

    @object = @klass.new
  end

  def test_should_raise_exception_if_invalid_event_specified
    exception = assert_raises(StateMachines::InvalidEvent) { @machines.fire_events(@object, :invalid) }
    assert_equal :invalid, exception.event

    exception = assert_raises(StateMachines::InvalidEvent) { @machines.fire_events(@object, :ignite, :invalid) }
    assert_equal :invalid, exception.event
  end

  def test_should_fail_if_any_event_cannot_transition
    refute @machines.fire_events(@object, :park, :disable_alarm)
    assert_equal 'parked', @object.state
    assert_equal 'active', @object.alarm_state
    refute @object.saved

    refute @machines.fire_events(@object, :ignite, :enable_alarm)
    assert_equal 'parked', @object.state
    assert_equal 'active', @object.alarm_state
    refute @object.saved
  end

  def test_should_run_failure_callbacks_if_any_event_cannot_transition
    @state_failure_run = @alarm_state_failure_run = false

    @machines[:state].after_failure { @state_failure_run = true }
    @machines[:alarm_state].after_failure { @alarm_state_failure_run = true }

    refute @machines.fire_events(@object, :park, :disable_alarm)
    assert @state_failure_run
    refute @alarm_state_failure_run
  end

  def test_should_be_successful_if_all_events_transition
    assert @machines.fire_events(@object, :ignite, :disable_alarm)
    assert_equal 'idling', @object.state
    assert_equal 'off', @object.alarm_state
    assert @object.saved
  end

  def test_should_not_save_if_skipping_action
    assert @machines.fire_events(@object, :ignite, :disable_alarm, false)
    assert_equal 'idling', @object.state
    assert_equal 'off', @object.alarm_state
    refute @object.saved
  end
end
