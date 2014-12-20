require 'test_helper'

class MachineCollectionByDefaultTest < MiniTest::Test
  def setup
    @machines = StateMachines::MachineCollection.new
  end

  def test_should_not_have_any_machines
    assert @machines.empty?
  end
end

class MachineCollectionStateInitializationTest < MiniTest::Test
  def setup
    @machines = StateMachines::MachineCollection.new

    @klass = Class.new

    @machines[:state] = StateMachines::Machine.new(@klass, :state, initial: :parked)
    @machines[:alarm_state] = StateMachines::Machine.new(@klass, :alarm_state, initial: lambda { |_object| :active })
    @machines[:alarm_state].state :active, value: lambda { 'active' }

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

  def test_should_only_initialize_static_states_prior_to_block
    @machines.initialize_states(@object) do
      @state_in_block = @object.state
      @alarm_state_in_block = @object.alarm_state
    end

    assert_equal 'parked', @state_in_block
    assert_nil @alarm_state_in_block
  end

  def test_should_only_initialize_dynamic_states_after_block
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

  def test_should_not_initialize_existing_static_states_by_default
    @object.state = 'idling'
    @machines.initialize_states(@object)
    assert_equal 'idling', @object.state
  end

  def test_should_initialize_existing_static_states_if_forced
    @object.state = 'idling'
    @machines.initialize_states(@object, static: :force)
    assert_equal 'parked', @object.state
  end

  def test_should_not_initialize_existing_static_states_if_not_forced
    @object.state = 'idling'
    @machines.initialize_states(@object, static: true)
    assert_equal 'idling', @object.state
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
end

class MachineCollectionFireTest < MiniTest::Test
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
    assert !@machines.fire_events(@object, :park, :disable_alarm)
    assert_equal 'parked', @object.state
    assert_equal 'active', @object.alarm_state
    assert !@object.saved

    assert !@machines.fire_events(@object, :ignite, :enable_alarm)
    assert_equal 'parked', @object.state
    assert_equal 'active', @object.alarm_state
    assert !@object.saved
  end

  def test_should_run_failure_callbacks_if_any_event_cannot_transition
    @state_failure_run = @alarm_state_failure_run = false

    @machines[:state].after_failure { @state_failure_run = true }
    @machines[:alarm_state].after_failure { @alarm_state_failure_run = true }

    assert !@machines.fire_events(@object, :park, :disable_alarm)
    assert @state_failure_run
    assert !@alarm_state_failure_run
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
    assert !@object.saved
  end
end

class MachineCollectionFireWithTransactionsTest < MiniTest::Test
  def setup
    @machines = StateMachines::MachineCollection.new

    @klass = Class.new do
      attr_accessor :allow_save

      def save
        @allow_save
      end
    end

    StateMachines::Integrations.const_set('Custom', Module.new do
      include StateMachines::Integrations::Base

      attr_reader :rolled_back

      def transaction(_object)
        @rolled_back = yield
      end
    end)

    # First machine
    @machines[:state] = @state = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save, integration: :custom)
    @state.event :ignite do
      transition parked: :idling
    end

    # Second machine
    @machines[:alarm_state] = @alarm_state = StateMachines::Machine.new(@klass, :alarm_state, initial: :active, action: :save, namespace: 'alarm', integration: :custom)
    @alarm_state.event :disable do
      transition active: :off
    end

    @object = @klass.new
  end

  def test_should_not_rollback_if_successful
    @object.allow_save = true

    assert @machines.fire_events(@object, :ignite, :disable_alarm)
    assert_equal true, @state.rolled_back
    assert_nil @alarm_state.rolled_back
    assert_equal 'idling', @object.state
    assert_equal 'off', @object.alarm_state
  end

  def test_should_rollback_if_not_successful
    @object.allow_save = false

    assert !@machines.fire_events(@object, :ignite, :disable_alarm)
    assert_equal false, @state.rolled_back
    assert_nil @alarm_state.rolled_back
    assert_equal 'parked', @object.state
    assert_equal 'active', @object.alarm_state
  end

  def test_should_run_failure_callbacks_if_not_successful
    @object.allow_save = false
    @state_failure_run = @alarm_state_failure_run = false

    @machines[:state].after_failure { @state_failure_run = true }
    @machines[:alarm_state].after_failure { @alarm_state_failure_run = true }

    assert !@machines.fire_events(@object, :ignite, :disable_alarm)
    assert @state_failure_run
    assert @alarm_state_failure_run
  end

  def teardown
    StateMachines::Integrations.send(:remove_const, 'Custom')
  end
end

class MachineCollectionFireWithValidationsTest < MiniTest::Test
  def setup
    StateMachines::Integrations.const_set('Custom', Module.new do
      include StateMachines::Integrations::Base

      def invalidate(object, _attribute, message, values = [])
        (object.errors ||= []) << generate_message(message, values)
      end

      def reset(object)
        object.errors = []
      end
    end)

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

    assert !@machines.fire_events(@object, :ignite, :disable_alarm)
    assert_equal ['cannot transition via "ignite"', 'cannot transition via "disable"'], @object.errors
  end

  def test_should_run_failure_callbacks_if_no_transitions_exist
    @object.state = 'idling'
    @object.alarm_state = 'off'
    @state_failure_run = @alarm_state_failure_run = false

    @machines[:state].after_failure { @state_failure_run = true }
    @machines[:alarm_state].after_failure { @alarm_state_failure_run = true }

    assert !@machines.fire_events(@object, :ignite, :disable_alarm)
    assert @state_failure_run
    assert @alarm_state_failure_run
  end

  def teardown
    StateMachines::Integrations.send(:remove_const, 'Custom')
  end
end

class MachineCollectionTransitionsWithoutEventsTest < MiniTest::Test
  def setup
    @klass = Class.new

    @machines = StateMachines::MachineCollection.new
    @machines[:state] = @machine = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
    @machine.event :ignite do
      transition parked: :idling
    end

    @object = @klass.new
    @object.state_event = nil
    @transitions = @machines.transitions(@object, :save)
  end

  def test_should_be_empty
    assert @transitions.empty?
  end

  def test_should_perform
    assert_equal true, @transitions.perform
  end
end

class MachineCollectionTransitionsWithBlankEventsTest < MiniTest::Test
  def setup
    @klass = Class.new

    @machines = StateMachines::MachineCollection.new
    @machines[:state] = @machine = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
    @machine.event :ignite do
      transition parked: :idling
    end

    @object = @klass.new
    @object.state_event = ''
    @transitions = @machines.transitions(@object, :save)
  end

  def test_should_be_empty
    assert @transitions.empty?
  end

  def test_should_perform
    assert_equal true, @transitions.perform
  end
end

class MachineCollectionTransitionsWithInvalidEventsTest < MiniTest::Test
  def setup
    @klass = Class.new

    @machines = StateMachines::MachineCollection.new
    @machines[:state] = @machine = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
    @machine.event :ignite do
      transition parked: :idling
    end

    @object = @klass.new
    @object.state_event = 'invalid'
    @transitions = @machines.transitions(@object, :save)
  end

  def test_should_be_empty
    assert @transitions.empty?
  end

  def test_should_not_perform
    assert_equal false, @transitions.perform
  end
end

class MachineCollectionTransitionsWithoutTransitionTest < MiniTest::Test
  def setup
    @klass = Class.new

    @machines = StateMachines::MachineCollection.new
    @machines[:state] = @machine = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
    @machine.event :ignite do
      transition parked: :idling
    end

    @object = @klass.new
    @object.state = 'idling'
    @object.state_event = 'ignite'
    @transitions = @machines.transitions(@object, :save)
  end

  def test_should_be_empty
    assert @transitions.empty?
  end

  def test_should_not_perform
    assert_equal false, @transitions.perform
  end
end

class MachineCollectionTransitionsWithTransitionTest < MiniTest::Test
  def setup
    @klass = Class.new

    @machines = StateMachines::MachineCollection.new
    @machines[:state] = @machine = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
    @machine.event :ignite do
      transition parked: :idling
    end

    @object = @klass.new
    @object.state_event = 'ignite'
    @transitions = @machines.transitions(@object, :save)
  end

  def test_should_not_be_empty
    assert_equal 1, @transitions.length
  end

  def test_should_perform
    assert_equal true, @transitions.perform
  end
end

class MachineCollectionTransitionsWithSameActionsTest < MiniTest::Test
  def setup
    @klass = Class.new

    @machines = StateMachines::MachineCollection.new
    @machines[:state] = @machine = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
    @machine.event :ignite do
      transition parked: :idling
    end
    @machines[:status] = @machine = StateMachines::Machine.new(@klass, :status, initial: :first_gear, action: :save)
    @machine.event :shift_up do
      transition first_gear: :second_gear
    end

    @object = @klass.new
    @object.state_event = 'ignite'
    @object.status_event = 'shift_up'
    @transitions = @machines.transitions(@object, :save)
  end

  def test_should_not_be_empty
    assert_equal 2, @transitions.length
  end

  def test_should_perform
    assert_equal true, @transitions.perform
  end
end

class MachineCollectionTransitionsWithDifferentActionsTest < MiniTest::Test
  def setup
    @klass = Class.new

    @machines = StateMachines::MachineCollection.new
    @machines[:state] = @state = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
    @state.event :ignite do
      transition parked: :idling
    end
    @machines[:status] = @status = StateMachines::Machine.new(@klass, :status, initial: :first_gear, action: :persist)
    @status.event :shift_up do
      transition first_gear: :second_gear
    end

    @object = @klass.new
    @object.state_event = 'ignite'
    @object.status_event = 'shift_up'
    @transitions = @machines.transitions(@object, :save)
  end

  def test_should_only_select_matching_actions
    assert_equal 1, @transitions.length
  end
end

class MachineCollectionTransitionsWithExisitingTransitionsTest < MiniTest::Test
  def setup
    @klass = Class.new

    @machines = StateMachines::MachineCollection.new
    @machines[:state] = @machine = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
    @machine.event :ignite do
      transition parked: :idling
    end

    @object = @klass.new
    @object.send(:state_event_transition=, StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling))
    @transitions = @machines.transitions(@object, :save)
  end

  def test_should_not_be_empty
    assert_equal 1, @transitions.length
  end

  def test_should_perform
    assert_equal true, @transitions.perform
  end
end

class MachineCollectionTransitionsWithCustomOptionsTest < MiniTest::Test
  def setup
    @klass = Class.new

    @machines = StateMachines::MachineCollection.new
    @machines[:state] = @machine = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
    @machine.event :ignite do
      transition parked: :idling
    end

    @object = @klass.new
    @transitions = @machines.transitions(@object, :save, after: false)
  end

  def test_should_use_custom_options
    assert @transitions.skip_after
  end
end

class MachineCollectionFireAttributesWithValidationsTest < MiniTest::Test
  def setup
    @klass = Class.new do
      attr_accessor :errors

      def initialize
        @errors = []
        super
      end
    end

    @machines = StateMachines::MachineCollection.new
    @machines[:state] = @machine = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
    @machine.event :ignite do
      transition parked: :idling
    end

    class << @machine
      def invalidate(object, _attribute, message, values = [])
        (object.errors ||= []) << generate_message(message, values)
      end

      def reset(object)
        object.errors = []
      end
    end

    @object = @klass.new
  end

  def test_should_invalidate_if_event_is_invalid
    @object.state_event = 'invalid'
    @machines.transitions(@object, :save)

    assert !@object.errors.empty?
  end

  def test_should_invalidate_if_no_transition_exists
    @object.state = 'idling'
    @object.state_event = 'ignite'
    @machines.transitions(@object, :save)

    assert !@object.errors.empty?
  end

  def test_should_not_invalidate_if_transition_exists
    @object.state_event = 'ignite'
    @machines.transitions(@object, :save)

    assert @object.errors.empty?
  end
end
