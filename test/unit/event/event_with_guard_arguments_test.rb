# frozen_string_literal: true

require_relative '../../test_helper'

class EventWithGuardArgumentsTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_accessor :trial_enabled, :force

      def initialize
        @trial_enabled = true
        @force = false
        super
      end

      def trial_enabled?
        @trial_enabled
      end

      def forced?
        @force
      end
    end

    @machine = StateMachines::Machine.new(@klass, initial: :uninitialized)
    @machine.other_states(:trial, :active, :future_active)
    @object = @klass.new
  end

  def test_backward_compatibility_with_single_parameter_guards
    # Single parameter guard (existing behavior)
    @machine.event :start do
      transition :uninitialized => :trial, if: ->(obj) { obj.trial_enabled? }
      transition :uninitialized => :active
    end

    @object.trial_enabled = true
    assert @object.start(:skip_trial)  # Event args should be ignored for single-param guards
    assert_equal "trial", @object.state
  end

  def test_backward_compatibility_with_symbol_guards
    # Symbol guards should continue working unchanged
    @machine.event :start do
      transition :uninitialized => :trial, if: :trial_enabled?
      transition :uninitialized => :active
    end

    @object.trial_enabled = true
    assert @object.start(:any_args, :should_be, :ignored)
    assert_equal "trial", @object.state
  end

  def test_new_guard_with_event_arguments_splat_parameters
    # Multi-parameter guard with splat (new behavior)
    @machine.event :start do
      transition :uninitialized => :trial, if: ->(obj, *args) { obj.trial_enabled? && !args.include?(:skip_trial) }
      transition :uninitialized => :active
    end

    # First transition: should go to trial when no skip argument
    @object.trial_enabled = true
    @object.state = "uninitialized"
    assert @object.start
    assert_equal "trial", @object.state

    # Second transition: should skip trial when :skip_trial argument is passed
    @object.state = "uninitialized"
    assert @object.start(:skip_trial)
    assert_equal "active", @object.state
  end

  def test_new_guard_with_event_arguments_explicit_parameters
    # Multi-parameter guard with explicit parameters (new behavior)
    @machine.event :start do
      transition :uninitialized => :future_active, if: ->(obj, skip_trial, future_date) { skip_trial && future_date }
      transition :uninitialized => :trial, if: ->(obj, skip_trial) { obj.trial_enabled? && !skip_trial }
      transition :uninitialized => :active
    end

    # Should go to future_active when both arguments are truthy
    @object.state = "uninitialized"
    assert @object.start(true, true)
    assert_equal "future_active", @object.state

    # Should go to trial when skip_trial is false (need 2 args for the first guard)
    @object.state = "uninitialized"
    assert @object.start(false, false)
    assert_equal "trial", @object.state

    # Should go to active when skipping trial but no future date
    @object.state = "uninitialized"
    assert @object.start(true, false)
    assert_equal "active", @object.state
  end

  def test_unless_guards_with_event_arguments
    # Test unless guards with event arguments
    @machine.event :start do
      transition :uninitialized => :trial, unless: ->(obj, *args) { args.include?(:skip_trial) }
      transition :uninitialized => :active
    end

    # Should go to trial when no skip argument
    @object.state = "uninitialized"
    assert @object.start
    assert_equal "trial", @object.state

    # Should go to active when skip argument is present
    @object.state = "uninitialized"
    assert @object.start(:skip_trial)
    assert_equal "active", @object.state
  end

  def test_mixed_guard_types_with_event_arguments
    # Test mixing single-param and multi-param guards
    @machine.event :start do
      transition :uninitialized => :future_active, if: ->(obj, *args) { args.include?(:future) }
      transition :uninitialized => :trial, if: ->(obj) { obj.trial_enabled? }
      transition :uninitialized => :active
    end

    # Should go to future_active when :future arg is passed
    @object.state = "uninitialized"
    assert @object.start(:future)
    assert_equal "future_active", @object.state

    # Should go to trial when no special args and trial enabled
    @object.state = "uninitialized"
    @object.trial_enabled = true
    assert @object.start
    assert_equal "trial", @object.state

    # Should go to active when trial disabled and no special args
    @object.state = "uninitialized"
    @object.trial_enabled = false
    assert @object.start
    assert_equal "active", @object.state
  end

  def test_zero_arity_guards_still_work
    # Test edge case of zero-arity guards
    called = false
    @machine.event :start do
      transition :uninitialized => :active, if: -> { called = true; true }
    end

    @object.state = "uninitialized"
    assert @object.start(:any, :args)
    assert_equal "active", @object.state
    assert called, "Zero-arity guard should have been called"
  end

  def test_complex_use_case_from_github_issue
    # Test the exact use case from GitHub issue #39
    @machine.event :start do
      transition :uninitialized => :trial, if: ->(subscription, *args) {
        subscription.trial_enabled? && (args.empty? || args[0] != true)
      }
      transition [:uninitialized, :trial] => :active
    end

    # Should start trial normally
    @object.trial_enabled = true
    @object.state = "uninitialized"
    assert @object.start
    assert_equal "trial", @object.state

    # Should skip trial when true argument is passed
    @object.state = "uninitialized"
    assert @object.start(true)
    assert_equal "active", @object.state
  end

  def test_method_guards_with_arguments_unsupported
    # Method objects currently don't support event arguments for security
    test_method = @object.method(:trial_enabled?)
    @machine.event :start do
      transition :uninitialized => :trial, if: test_method
      transition :uninitialized => :active
    end

    @object.trial_enabled = true
    @object.state = "uninitialized"
    assert @object.start(:any_args)
    assert_equal "trial", @object.state  # Should work normally, ignoring args
  end

  def test_string_guards_with_arguments_unsupported
    # String guards don't support event arguments for security
    @machine.event :start do
      transition :uninitialized => :trial, if: 'trial_enabled?'
      transition :uninitialized => :active
    end

    @object.trial_enabled = true
    @object.state = "uninitialized"
    assert @object.start(:any_args)
    assert_equal "trial", @object.state  # Should work normally, ignoring args
  end
end
