# frozen_string_literal: true

require 'test_helper'
require 'files/models/vehicle'

class VehicleCallbacksTest < StateMachinesTest
  def setup
    @vehicle = Vehicle.new
  end

  # Test that the Vehicle class has the expected callback definitions
  def test_should_have_before_transition_put_on_seatbelt
    assert_before_transition(Vehicle, from: :parked, do: :put_on_seatbelt)
  end

  def test_should_have_before_transition_increase_insurance_premium
    assert_before_transition(Vehicle, to: :stalled, do: :increase_insurance_premium)
  end

  def test_should_have_after_transition_tow_on_crash
    assert_after_transition(Vehicle, on: :crash, do: :tow)
  end

  def test_should_have_after_transition_fix_on_repair
    assert_after_transition(Vehicle, on: :repair, do: :fix)
  end

  # Test that events actually trigger through method calls (indirect event testing)
  def test_crash_should_trigger_crash_event
    @vehicle.ignite # Get to first gear
    @vehicle.shift_up

    # Ensure auto shop is available (required condition for crash)
    assert_predicate @vehicle.auto_shop, :available?, 'Auto shop should be available for crash event'

    # The crash method should trigger the crash event
    assert_sm_triggers_event(@vehicle, :crash) do
      @vehicle.crash!
    end
  end

  def test_ignite_should_trigger_ignite_event_from_parked
    # Test direct event triggering
    assert_sm_triggers_event(@vehicle, :ignite) do
      @vehicle.ignite!
    end
  end

  def test_park_should_trigger_park_event_from_idling
    @vehicle.ignite # Get to idling state

    assert_sm_triggers_event(@vehicle, :park) do
      @vehicle.park!
    end
  end

  # Test callback execution (the callbacks actually work)
  def test_put_on_seatbelt_callback_executes
    refute @vehicle.seatbelt_on
    @vehicle.ignite

    assert @vehicle.seatbelt_on, 'Expected seatbelt to be on after leaving parked state'
  end

  def test_remove_seatbelt_callback_executes
    @vehicle.ignite # Put seatbelt on

    assert @vehicle.seatbelt_on

    @vehicle.park # Should remove seatbelt

    refute @vehicle.seatbelt_on, 'Expected seatbelt to be off after parking'
  end

  def test_insurance_premium_increases_when_stalling
    original_premium = @vehicle.insurance_premium
    @vehicle.ignite
    @vehicle.shift_up  # Get to first gear
    @vehicle.crash!    # Should transition to stalled and increase premium

    assert_operator @vehicle.insurance_premium, :>, original_premium
  end
end
