require_relative '../../test_helper'

class MachineCollectionFireWithValidationsTest < StateMachinesTest
  module Custom
    include StateMachines::Integrations::Base

    def invalidate(object, _attribute, message, values = [])
      (object.errors ||= []) << generate_message(message, values)
    end

    def reset(object)
      object.errors = []
    end
  end

  def setup
    StateMachines::Integrations.register(MachineCollectionFireWithValidationsTest::Custom)

    @klass = Class.new do
      attr_accessor :errors

      def initialize
        @errors = []
        super
      end
    end

    @machines = StateMachines::MachineCollection.new
    @machines[:state] = @state = StateMachines::Machine.new(@klass, :state, initial: :parked, integration: :custom)
    @state.event :ignite do
      transition parked: :idling
    end

    @machines[:alarm_state] = @alarm_state = StateMachines::Machine.new(@klass, :alarm_state, initial: :active, namespace: 'alarm', integration: :custom)
    @alarm_state.event :disable do
      transition active: :off
    end

    @object = @klass.new
  end

  def test_should_not_invalidate_if_transitions_exist
    assert @machines.fire_events(@object, :ignite, :disable_alarm)
    assert_equal [], @object.errors
  end

  def test_should_invalidate_if_no_transitions_exist
    @object.state = 'idling'
    @object.alarm_state = 'off'

    refute @machines.fire_events(@object, :ignite, :disable_alarm)
    assert_equal ['cannot transition via "ignite"', 'cannot transition via "disable"'], @object.errors
  end

  def test_should_run_failure_callbacks_if_no_transitions_exist
    @object.state = 'idling'
    @object.alarm_state = 'off'
    @state_failure_run = @alarm_state_failure_run = false

    @machines[:state].after_failure { @state_failure_run = true }
    @machines[:alarm_state].after_failure { @alarm_state_failure_run = true }

    refute @machines.fire_events(@object, :ignite, :disable_alarm)
    assert @state_failure_run
    assert @alarm_state_failure_run
  end

  def teardown
    StateMachines::Integrations.reset
  end
end

