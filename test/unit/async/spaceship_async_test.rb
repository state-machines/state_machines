# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)
require File.expand_path('../../files/models/autonomous_drone', __dir__)

class SpaceShipAsyncModeTest < Minitest::Test
  include StateMachines::TestHelper

  def setup
    # Skip async tests on unsupported Ruby engines where gems aren't available
    if RUBY_ENGINE == 'jruby' || RUBY_ENGINE == 'truffleruby'
      skip "Async tests not supported on #{RUBY_ENGINE} - async gems not available on this platform"
    end

    @spaceship = AutonomousDrone.new
  end

  def test_async_mode_configuration
    # Test that specific machines have async mode enabled
    assert_sm_async_mode(@spaceship, :status)
    assert_sm_async_mode(@spaceship, :shields)
    assert_sm_async_mode(@spaceship, :teleporter_status)

    # Test that weapons machine is sync-only
    assert_sm_sync_mode(@spaceship, :weapons)

    # Test bulk async machine checking
    assert_sm_has_async(@spaceship, [:status, :teleporter_status, :shields])
  end

  def test_thread_safe_methods_included_for_async_machines
    # AsyncMode machines should have thread-safe methods
    assert_sm_thread_safe_methods(@spaceship)

    # Async event methods should be available
    assert_sm_async_methods(@spaceship)
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
    assert_sm_async_event_methods(@spaceship, :launch)
    assert_sm_async_event_methods(@spaceship, :enter_warp)
    assert_sm_async_event_methods(@spaceship, :raise_shields)

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
    assert_sm_sync_mode(sync_ship, :status)

    # Should not have async methods
    assert_sm_no_async_methods(sync_ship)
    assert_sm_all_sync(sync_ship)

    # But regular sync methods should work
    assert_sm_sync_execution(sync_ship, :launch, :flying, :status)
  end
end
