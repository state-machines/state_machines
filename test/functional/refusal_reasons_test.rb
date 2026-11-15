# frozen_string_literal: true

require 'test_helper'

class RefusalReasonsTest < StateMachinesTest
  # Persists through an action hook, like the ORM integrations: the event
  # method hands its transition to +save+, which performs it again inside
  class Persisted
    attr_accessor :save_result

    def save
      save_result
    end
  end

  class Rocket < Persisted
    attr_accessor :fuelled, :abort_launch, :jam_hatch, :fail_scan

    def initialize
      @fuelled = true
      @save_result = true
      super
    end

    state_machine :state, initial: :grounded, action: :save do
      before_transition on: :launch do |rocket|
        throw :halt if rocket.abort_launch
      end

      around_transition on: :open_hatch do |rocket, _transition, block|
        block.call unless rocket.jam_hatch
      end

      event :launch do
        transition grounded: :flying, if: :fuelled
      end

      event :land do
        transition flying: :grounded
      end

      event :open_hatch do
        transition grounded: same
      end
    end

    state_machine :scanner, initial: :standby, action: :save do
      before_transition on: :scan do |rocket|
        throw :halt if rocket.fail_scan
      end

      event :scan do
        transition standby: :sweeping
      end

      event :stop_scan do
        transition sweeping: :standby
      end
    end
  end

  # Runs its action directly, without an action hook
  class Probe
    attr_accessor :transmit_result

    state_machine :state, initial: :docked, action: :transmit do
      event :undock do
        transition docked: :drifting
      end
    end

    def transmit
      raise IOError, 'antenna down' if transmit_result == :raise

      transmit_result
    end
  end

  # No action at all
  class Drone
    attr_accessor :grounded_by_rules

    state_machine :state, initial: :idle do
      before_transition on: :hover do |drone|
        throw :halt if drone.grounded_by_rules
      end

      event :hover do
        transition idle: :hovering
      end

      event :ascend do
        transition hovering: :climbing, unless: ->(_drone) { true }
      end
    end
  end

  class Satellite
    state_machine :orbit, initial: :parked, async: true do
      event(:launch) { transition parked: :cruising }
    end
  end

  def setup
    @rocket = Rocket.new
  end

  def test_should_have_no_refusal_before_any_attempt
    assert_nil @rocket.launch_refusal
  end

  def test_should_report_no_transition
    refute @rocket.land

    assert_equal :no_transition, @rocket.land_refusal
    assert_nil @rocket.launch_refusal
  end

  def test_should_report_guard
    @rocket.fuelled = false

    refute @rocket.launch
    assert_equal :guard, @rocket.launch_refusal
  end

  def test_should_report_guard_for_unless_conditions
    drone = Drone.new
    drone.hover

    refute drone.ascend
    assert_equal :guard, drone.ascend_refusal
  end

  def test_should_report_no_transition_rather_than_guard_when_no_branch_leaves_the_state
    @rocket.fuelled = false
    @rocket.launch
    @rocket.state = 'flying'

    refute @rocket.launch
    assert_equal :no_transition, @rocket.launch_refusal
  end

  def test_should_not_evaluate_guards_again_to_find_the_reason
    calls = 0
    klass = Class.new do
      state_machine initial: :parked do
        event(:ignite) { transition parked: :idling, if: ->(_object) { (calls += 1) && false } }
      end
    end

    object = klass.new
    object.ignite

    assert_equal 1, calls
    assert_equal :guard, object.ignite_refusal
  end

  def test_should_report_halted_by_before_callback
    @rocket.abort_launch = true

    refute @rocket.launch
    assert_equal :halted, @rocket.launch_refusal
    assert_equal 'grounded', @rocket.state
  end

  def test_should_report_halted_by_around_callback_that_does_not_yield
    @rocket.jam_hatch = true

    refute @rocket.open_hatch
    assert_equal :halted, @rocket.open_hatch_refusal
  end

  def test_should_report_halted_without_an_action
    drone = Drone.new
    drone.grounded_by_rules = true

    refute drone.hover
    assert_equal :halted, drone.hover_refusal
  end

  def test_should_report_action_failed_through_an_action_hook
    @rocket.save_result = false

    refute @rocket.launch
    assert_equal :action_failed, @rocket.launch_refusal
    assert_equal 'grounded', @rocket.state
  end

  def test_should_report_action_failed_without_an_action_hook
    probe = Probe.new
    probe.transmit_result = false

    refute probe.undock
    assert_equal :action_failed, probe.undock_refusal
  end

  def test_should_report_action_failed_when_the_action_raises
    probe = Probe.new
    probe.transmit_result = :raise

    assert_raises(IOError) { probe.undock }
    assert_equal :action_failed, probe.undock_refusal
    assert_equal 'docked', probe.state
  end

  def test_should_not_report_a_callback_exception_as_a_refusal
    klass = Class.new do
      state_machine initial: :idle do
        before_transition { raise ArgumentError }
        event(:hover) { transition idle: :hovering }
      end
    end
    drone = klass.new

    assert_raises(ArgumentError) { drone.hover }
    assert_nil drone.hover_refusal
  end

  def test_should_report_contended_when_the_state_moves_before_the_claim
    skip "Async tests not supported on #{RUBY_ENGINE}" if %w[jruby truffleruby].include?(RUBY_ENGINE)

    satellite = Satellite.new
    transition = satellite.launch_transition
    satellite.orbit = 'cruising'

    refute transition.perform
    assert_equal :contended, transition.refusal
    assert_equal :contended, satellite.launch_refusal
  end

  def test_should_return_false_on_refusal
    @rocket.fuelled = false

    assert_same false, @rocket.launch
  end

  def test_should_return_the_transition_on_success
    transition = @rocket.launch

    assert_kind_of StateMachines::Transition, transition
    assert_equal :launch, transition.event
    assert_equal 'flying', transition.to
  end

  def test_should_clear_the_refusal_after_success
    @rocket.fuelled = false
    @rocket.launch
    @rocket.fuelled = true

    assert @rocket.launch
    assert_nil @rocket.launch_refusal
  end

  def test_should_replace_the_refusal_on_each_attempt
    @rocket.fuelled = false
    @rocket.launch
    @rocket.fuelled = true
    @rocket.abort_launch = true
    @rocket.launch

    assert_equal :halted, @rocket.launch_refusal
  end

  def test_should_keep_refusals_per_event
    @rocket.land
    @rocket.fuelled = false
    @rocket.launch

    assert_equal :no_transition, @rocket.land_refusal
    assert_equal :guard, @rocket.launch_refusal
  end

  def test_should_keep_refusals_per_object
    other = Rocket.new
    @rocket.land

    assert_nil other.land_refusal
  end

  def test_should_report_through_the_generic_event_helper
    refute @rocket.fire_state_event(:land)
    assert_equal :no_transition, @rocket.land_refusal
  end

  def test_should_report_through_the_event_api
    @rocket.land

    assert_equal :no_transition, Rocket.state_machine.events[:land].refusal(@rocket)
  end

  def test_should_report_on_a_transition_performed_directly
    @rocket.abort_launch = true
    transition = @rocket.launch_transition

    refute transition.perform
    assert_equal :halted, transition.refusal
    assert_equal :halted, @rocket.launch_refusal
  end

  def test_should_report_through_event_attributes
    @rocket.abort_launch = true
    @rocket.state_event = 'launch'

    refute @rocket.save
    assert_equal :halted, @rocket.launch_refusal
  end

  def test_should_report_invalid_event_attributes
    @rocket.state_event = 'land'

    refute @rocket.save
    assert_equal :no_transition, @rocket.land_refusal
  end

  def test_should_carry_no_transition_on_bang
    error = assert_raises(StateMachines::InvalidTransition) { @rocket.land! }

    assert_equal :no_transition, error.reason
  end

  def test_should_carry_guard_on_bang
    @rocket.fuelled = false
    error = assert_raises(StateMachines::InvalidTransition) { @rocket.launch! }

    assert_equal :guard, error.reason
  end

  def test_should_carry_halted_on_bang
    @rocket.abort_launch = true
    error = assert_raises(StateMachines::InvalidTransition) { @rocket.launch! }

    assert_equal :halted, error.reason
  end

  def test_should_carry_action_failed_on_bang
    @rocket.save_result = false
    error = assert_raises(StateMachines::InvalidTransition) { @rocket.launch! }

    assert_equal :action_failed, error.reason
  end

  def test_should_report_only_the_event_without_a_transition_in_parallel
    refute @rocket.fire_events(:launch, :stop_scan)

    assert_nil @rocket.launch_refusal
    assert_equal :no_transition, @rocket.stop_scan_refusal
  end

  def test_should_report_only_the_halting_event_in_parallel
    @rocket.fail_scan = true

    refute @rocket.fire_events(:launch, :scan)
    assert_nil @rocket.launch_refusal
    assert_equal :halted, @rocket.scan_refusal
  end

  def test_should_report_the_halting_event_in_parallel_whatever_its_position
    @rocket.abort_launch = true

    refute @rocket.fire_events(:launch, :scan)
    assert_equal :halted, @rocket.launch_refusal
    assert_nil @rocket.scan_refusal
  end

  def test_should_report_action_failed_for_every_event_in_parallel
    @rocket.save_result = false

    refute @rocket.fire_events(:launch, :scan)
    assert_equal :action_failed, @rocket.launch_refusal
    assert_equal :action_failed, @rocket.scan_refusal
  end

  def test_should_clear_parallel_refusals_after_success
    @rocket.save_result = false
    @rocket.fire_events(:launch, :scan)
    @rocket.save_result = true

    assert @rocket.fire_events(:launch, :scan)
    assert_nil @rocket.launch_refusal
    assert_nil @rocket.scan_refusal
  end

  def test_should_carry_parallel_reasons_on_bang
    @rocket.fuelled = false
    error = assert_raises(StateMachines::InvalidParallelTransition) { @rocket.fire_events!(:launch, :stop_scan) }

    assert_equal({ launch: :guard, stop_scan: :no_transition }, error.reasons)
  end

  def test_should_leave_bystanders_out_of_parallel_reasons_on_bang
    @rocket.fail_scan = true
    error = assert_raises(StateMachines::InvalidParallelTransition) { @rocket.fire_events!(:launch, :scan) }

    assert_equal({ scan: :halted }, error.reasons)
  end

  def test_should_clear_the_refusal_when_an_after_callback_raises_on_success
    klass = Class.new(Probe) do
      attr_accessor :explode

      state_machine.after_transition(on: :undock) { |probe| raise ArgumentError if probe.explode }
    end
    probe = klass.new
    probe.transmit_result = false
    probe.undock
    probe.transmit_result = true
    probe.explode = true

    assert_raises(ArgumentError) { probe.undock }
    assert_equal 'drifting', probe.state
    assert_nil probe.undock_refusal
  end

  def test_should_clear_the_refusal_when_a_before_callback_raises_after_a_halt
    klass = Class.new do
      attr_accessor :halt, :explode

      state_machine initial: :idle do
        before_transition { |drone| throw :halt if drone.halt }
        before_transition { |drone| raise ArgumentError if drone.explode }
        event(:hover) { transition idle: :hovering }
      end
    end
    drone = klass.new
    drone.halt = true
    drone.hover
    drone.halt = false
    drone.explode = true

    assert_raises(ArgumentError) { drone.hover }
    assert_nil drone.hover_refusal
  end

  def test_should_clear_the_refusal_when_a_guard_raises
    klass = Class.new do
      attr_accessor :explode

      state_machine initial: :idle do
        event(:hover) { transition idle: :hovering, if: ->(drone) { drone.explode ? raise(ArgumentError) : false } }
      end
    end
    drone = klass.new
    drone.hover
    drone.explode = true

    assert_raises(ArgumentError) { drone.hover }
    assert_nil drone.hover_refusal
  end

  def test_should_start_a_dup_without_refusals
    @rocket.land
    copy = @rocket.dup

    assert_nil copy.land_refusal
    copy.state = 'flying'
    copy.land

    assert_equal :no_transition, @rocket.land_refusal
  end

  def test_should_start_a_clone_without_refusals
    @rocket.land
    copy = @rocket.clone
    copy.fuelled = false
    copy.launch

    assert_nil copy.land_refusal
    assert_nil @rocket.launch_refusal
  end

  def test_should_start_a_copy_without_refusals_through_a_user_defined_initialize_copy
    klass = Class.new(Rocket) do
      attr_reader :copied

      def initialize_copy(orig)
        super
        @copied = true
      end
    end
    rocket = klass.new
    rocket.land
    copy = rocket.dup

    assert copy.copied
    assert_nil copy.land_refusal
    assert_equal :no_transition, rocket.land_refusal
  end

  def test_should_keep_a_frozen_clone_frozen
    @rocket.land
    copy = @rocket.freeze.clone

    assert_predicate copy, :frozen?
    assert_nil copy.land_refusal
  end

  def test_should_refuse_on_a_frozen_object_without_recording_a_reason
    drone = Drone.new.freeze

    assert_same false, drone.ascend
    assert_nil drone.ascend_refusal
  end

  def test_should_report_no_reason_once_the_object_is_frozen
    drone = Drone.new
    drone.ascend
    drone.freeze

    assert_same false, drone.ascend
    assert_nil drone.ascend_refusal
  end

  def test_should_report_contended_only_on_the_contended_transition_in_parallel
    skip "Async tests not supported on #{RUBY_ENGINE}" if %w[jruby truffleruby].include?(RUBY_ENGINE)

    klass = Class.new do
      state_machine :orbit, initial: :parked, async: true do
        event(:launch) { transition parked: :cruising }
      end

      state_machine :beacon, initial: :off, namespace: 'beacon' do
        event(:light) { transition off: :on }
      end
    end
    satellite = klass.new
    launch = satellite.launch_transition
    light = satellite.light_beacon_transition
    satellite.orbit = 'cruising'

    refute StateMachines::TransitionCollection.new([launch, light]).perform
    assert_equal [:contended, nil], [launch.refusal, light.refusal]
    assert_equal [:contended, nil], [satellite.launch_refusal, satellite.light_beacon_refusal]
  end

  def test_should_not_lose_a_refusal_recorded_concurrently_with_the_first_one
    klass = Class.new do
      state_machine initial: :idle do
        event(:land) { transition flying: :idle }
        event(:dock) { transition drifting: :idle }
      end
    end
    drone = klass.new
    paused = Queue.new
    resume = Queue.new
    first = true
    drone.define_singleton_method(:instance_variable_get) do |name|
      value = super(name)
      if name == StateMachines::Event::REFUSALS_VARIABLE && value.nil? && first
        first = false
        paused << true
        resume.pop
      end
      value
    end

    lander = Thread.new { drone.land }
    paused.pop
    docker = Thread.new { drone.dock }
    docker.join(0.2)
    resume << true
    [lander, docker].each(&:join)

    assert_equal :no_transition, drone.land_refusal
    assert_equal :no_transition, drone.dock_refusal
  end

  def test_should_carry_the_reason_of_a_nested_collection_that_halted
    @rocket.fail_scan = true
    @rocket.scanner_event = 'scan'

    refute @rocket.launch
    assert_equal :halted, @rocket.launch_refusal
    assert_equal :halted, @rocket.scan_refusal
  end

  def test_should_carry_the_reason_of_a_nested_collection_that_halted_on_bang
    @rocket.fail_scan = true
    @rocket.scanner_event = 'scan'
    error = assert_raises(StateMachines::InvalidTransition) { @rocket.launch! }

    assert_equal :halted, error.reason
  end

  def test_should_carry_the_reason_of_an_invalid_nested_event_attribute
    @rocket.scanner_event = 'stop_scan'

    refute @rocket.launch
    assert_equal :no_transition, @rocket.launch_refusal
    assert_equal :no_transition, @rocket.stop_scan_refusal
  end
end
