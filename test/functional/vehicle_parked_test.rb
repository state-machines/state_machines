# frozen_string_literal: true

require 'test_helper'
require 'files/models/vehicle'

class VehicleParkedTest < StateMachinesTest
  def setup
    @vehicle = Vehicle.new
  end

  def test_should_be_in_parked_state
    assert_equal 'parked', @vehicle.state
  end

  def test_should_not_have_the_seatbelt_on
    refute @vehicle.seatbelt_on
  end

  def test_should_not_allow_park
    refute @vehicle.park
  end

  def test_should_allow_ignite
    assert_sm_event_triggers(@vehicle, :ignite)
    assert_equal 'idling', @vehicle.state
  end

  def test_should_not_allow_idle
    refute_sm_event_triggers(@vehicle, :idle)
  end

  def test_should_not_allow_shift_up
    refute_sm_event_triggers(@vehicle, :shift_up)
  end

  def test_should_not_allow_shift_down
    refute_sm_event_triggers(@vehicle, :shift_down)
  end

  def test_should_not_allow_crash
    refute_sm_event_triggers(@vehicle, :crash)
  end

  def test_should_not_allow_repair
    refute_sm_event_triggers(@vehicle, :repair)
  end

  def test_should_raise_exception_if_repair_not_allowed!
    assert_sm_event_raises_error(@vehicle, :repair, StateMachines::InvalidTransition)
  end
end
