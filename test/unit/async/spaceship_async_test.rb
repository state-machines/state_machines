# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)
require File.expand_path('../../files/models/autonomous_drone', __dir__)

# Async gem is required - no conditional loading
require 'state_machines/async_mode'

class SpaceShipAsyncModeTest < Minitest::Test
  def setup
    @spaceship = AutonomousDrone.new
  end

  def test_async_mode_configuration

    # Check which machines have async mode enabled
    status_machine = @spaceship.class.state_machine(:status)
    weapons_machine = @spaceship.class.state_machine(:weapons)
    shields_machine = @spaceship.class.state_machine(:shields)
    teleporter_machine = @spaceship.class.state_machine(:teleporter_status)

    assert status_machine.async_mode_enabled?, "Status machine should have async mode enabled"
    refute weapons_machine.async_mode_enabled?, "Weapons machine should NOT have async mode enabled"
    assert shields_machine.async_mode_enabled?, "Shields machine should have async mode enabled"
    assert teleporter_machine.async_mode_enabled?, "Teleporter machine should have async mode enabled"
  end

  def test_thread_safe_methods_included_for_async_machines

    # AsyncMode machines should have thread-safe methods
    assert @spaceship.respond_to?(:state_machine_mutex)
    assert @spaceship.respond_to?(:read_state_safely)
    assert @spaceship.respond_to?(:write_state_safely)

    # Async event methods should be available
    assert @spaceship.respond_to?(:async_fire_event)
    assert @spaceship.respond_to?(:fire_event_async)
    assert @spaceship.respond_to?(:fire_events_async)
  end

  def test_spaceship_launch_sequence_sync

    # Standard synchronous operation still works
    assert_equal 'docked', @spaceship.status
    assert_equal 'standby', @spaceship.weapons
    assert_equal 'down', @spaceship.shields

    # Launch sequence
    result = @spaceship.launch
    assert_equal true, result
    assert_equal 'flying', @spaceship.status

    # Arm weapons (sync only machine)
    result = @spaceship.arm_weapons!
    assert_equal true, result
    assert_equal 'armed', @spaceship.weapons

    # Raise shields
    result = @spaceship.raise_shields
    assert_equal true, result
    assert_equal 'up', @spaceship.shields
  end

  def test_spaceship_launch_sequence_async
    require 'async'

    Async do
      # Test async launch sequence
      assert_equal 'docked', @spaceship.status
      result = @spaceship.fire_event_async(:launch)
      assert_equal true, result
      assert_equal 'flying', @spaceship.status

      # Test async shield raising
      result = @spaceship.fire_event_async(:raise_shields)
      assert_equal true, result
      assert_equal 'up', @spaceship.shields

      # Weapons system is sync-only, so should use regular method
      result = @spaceship.arm_weapons!
      assert_equal true, result
      assert_equal 'armed', @spaceship.weapons
    end
  end

  def test_concurrent_spaceship_operations
    require 'async'

    # Test multiple spaceships operating concurrently
    ships = 3.times.map { AutonomousDrone.new }

    Async do
      # Launch all ships concurrently
      launch_tasks = ships.map do |ship|
        ship.async_fire_event(:launch)
      end

      # Wait for all launches to complete
      results = launch_tasks.map(&:wait)
      assert_equal [true, true, true], results

      # All ships should be flying
      ships.each do |ship|
        assert_equal 'flying', ship.status
      end

      # Raise shields on all ships concurrently
      shield_tasks = ships.map do |ship|
        ship.async_fire_event(:raise_shields)
      end

      shield_results = shield_tasks.map(&:wait)
      assert_equal [true, true, true], shield_results

      # All shields should be up
      ships.each do |ship|
        assert_equal 'up', ship.shields
      end
    end
  end

  def test_thread_safety_with_multiple_spaceships

    # Test thread safety with multiple threads accessing same spaceship
    threads = []
    results = []
    results_mutex = Mutex.new

    # Multiple threads trying to launch the same spaceship
    5.times do |i|
      threads << Thread.new do
        begin
          result = @spaceship.fire_event_async(:launch)
          results_mutex.synchronize do
            results << { thread: i, result: result, status: @spaceship.status }
          end
        rescue => e
          results_mutex.synchronize do
            results << { thread: i, error: e.message }
          end
        end
      end
    end

    threads.each(&:join)

    # Only one thread should successfully launch, others should fail
    successful_launches = results.count { |r| r[:result] == true }
    assert_equal 1, successful_launches, "Only one thread should successfully launch"
    assert_equal 'flying', @spaceship.status
  end

  def test_callbacks_work_with_async_mode

    assert_equal [], @spaceship.callback_log

    # Test that callbacks work with async operations
    result = @spaceship.fire_event_async(:launch)
    assert_equal true, result
    assert_equal 'flying', @spaceship.status

    # Check that callbacks were executed
    assert_includes @spaceship.callback_log, "Autonomous flight sequence initiated..."
    assert_includes @spaceship.callback_log, "Drone airborne - autonomous navigation active!"
  end

  def test_mixed_sync_and_async_operations

    # Launch (async-enabled machine)
    launch_result = @spaceship.fire_event_async(:launch)
    assert_equal true, launch_result
    assert_equal 'flying', @spaceship.status

    # Arm weapons (sync-only machine) - should work normally
    weapons_result = @spaceship.arm_weapons!
    assert_equal true, weapons_result
    assert_equal 'armed', @spaceship.weapons

    # Raise shields (async-enabled machine)
    shields_result = @spaceship.fire_event_async(:raise_shields)
    assert_equal true, shields_result
    assert_equal 'up', @spaceship.shields
  end

  def test_spaceship_emergency_procedures

    require 'async'
      # Get to warping state first
      @spaceship.launch!
      @spaceship.enter_warp!
      assert_equal 'warping', @spaceship.status
      Async do
        # Exit warp should work async
        emergency_task = @spaceship.async_fire_event(:exit_warp)
        result = emergency_task.wait
          assert_equal true, result
        assert_equal 'flying', @spaceship.status
      end

  end

  def test_backward_compatibility_not_broken

    # All standard sync methods should still work exactly as before
    assert_equal 'docked', @spaceship.status

    # Launch using regular sync method
    result = @spaceship.launch!
    assert_equal true, result
    assert_equal 'flying', @spaceship.status

    # Enter warp using regular sync method
    result = @spaceship.enter_warp!
    assert_equal true, result
    assert_equal 'warping', @spaceship.status

    # Land using regular sync method
    result = @spaceship.exit_warp!
    assert_equal true, result
    assert_equal 'flying', @spaceship.status

    result = @spaceship.land!
    assert_equal true, result
    assert_equal 'docked', @spaceship.status
  end

  def test_async_bang_methods_raise_exceptions_on_invalid_transitions

    require 'async'
      # Try to launch from flying state (invalid transition)
      @spaceship.launch! # First get to flying state
      assert_equal 'flying', @spaceship.status
      Async do
        # This should raise an exception when awaited because launch is invalid from flying
        begin
          task = @spaceship.launch_async!
          task.wait # This should raise StateMachines::InvalidTransition
          flunk "Expected StateMachines::InvalidTransition to be raised"
        rescue StateMachines::InvalidTransition => e
          assert_match(/launch/, e.message)
          assert_includes e.message, 'flying'
        end
          # Test that fire_event_async! also raises exceptions
        begin
          @spaceship.fire_event_async!(:launch)
          flunk "Expected StateMachines::InvalidTransition to be raised"
        rescue StateMachines::InvalidTransition => e
          assert_match(/launch/, e.message)
        end
      end

  end

  def test_async_bang_methods_succeed_on_valid_transitions

    require 'async'
      # Test valid transitions don't raise exceptions
      assert_equal 'docked', @spaceship.status
      Async do
        # Valid transition should work fine
        task = @spaceship.launch_async!
        result = task.wait
        assert_equal true, result
        assert_equal 'flying', @spaceship.status
          # Test fire_event_async! with valid transition
        result = @spaceship.fire_event_async!(:enter_warp)
        assert_equal true, result
        assert_equal 'warping', @spaceship.status
      end

  end

  def test_individual_event_async_methods_are_generated

    # Check that async versions of individual events are generated for async machines
    assert @spaceship.respond_to?(:launch_async), "Should have launch_async method"
    assert @spaceship.respond_to?(:launch_async!), "Should have launch_async! method"
    assert @spaceship.respond_to?(:enter_warp_async), "Should have enter_warp_async method"
    assert @spaceship.respond_to?(:enter_warp_async!), "Should have enter_warp_async! method"

    # Shields machine is async-enabled
    assert @spaceship.respond_to?(:raise_shields_async), "Should have raise_shields_async method"
    assert @spaceship.respond_to?(:raise_shields_async!), "Should have raise_shields_async! method"

    # Weapons machine is sync-only, so should NOT have async versions
    refute @spaceship.respond_to?(:arm_weapons_async), "Should NOT have arm_weapons_async method (weapons is sync-only)"
    refute @spaceship.respond_to?(:arm_weapons_async!), "Should NOT have arm_weapons_async! method (weapons is sync-only)"
  end

  def test_async_mode_enables_per_machine_not_globally

    # Create a spaceship class without any async mode
    sync_only_spaceship_class = Class.new do
      attr_accessor :status
      state_machine :status, initial: :docked do
        # No async: true parameter
          event :launch do
          transition docked: :flying
        end
      end
      def initialize
        super
      end
    end

    sync_ship = sync_only_spaceship_class.new

    # This machine should NOT have async mode enabled
    refute sync_ship.class.state_machine(:status).async_mode_enabled?

    # Should not have async methods
    refute sync_ship.respond_to?(:fire_event_async)
    refute sync_ship.respond_to?(:async_fire_event)

    # But regular sync methods should work
    assert_equal 'docked', sync_ship.status
    result = sync_ship.launch
    assert_equal true, result
    assert_equal 'flying', sync_ship.status
  end
end

# Test graceful fallback when AsyncMode is not available
class SpaceShipFallbackTest < Minitest::Test
  def test_spaceship_works_without_async_mode
    # Test that spaceships work fine without AsyncMode
    spaceship_class = Class.new do
      attr_accessor :status
      state_machine :status, initial: :docked do
        event :launch do
          transition docked: :flying
        end
      end
      def initialize
        super
      end
    end

    spaceship = spaceship_class.new

    # Basic functionality should work
    assert_equal 'docked', spaceship.status

    result = spaceship.launch
    assert_equal true, result
    assert_equal 'flying', spaceship.status

    # AsyncMode methods should not be available
    refute spaceship.respond_to?(:fire_event_async)
    refute spaceship.respond_to?(:async_fire_event)
  end
end
