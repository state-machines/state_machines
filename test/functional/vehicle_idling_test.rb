# frozen_string_literal: true

require 'test_helper'
require 'files/models/vehicle'

class VehicleIdlingTest < StateMachinesTest
  def setup
    @vehicle = Vehicle.new
    @vehicle.ignite
  end

  def test_should_be_in_idling_state
    assert_sm_state(@vehicle, :idling)
  end

  def test_should_be_idling
    assert_predicate @vehicle, :idling?
  end

  def test_should_have_seatbelt_on
    assert @vehicle.seatbelt_on
  end

  def test_should_track_time_elapsed
    refute_nil @vehicle.time_elapsed
  end

  def test_should_allow_park
    assert_sm_can_transition(@vehicle, :park)
  end

  def test_should_call_park_with_bang_action
    class << @vehicle
      def park
        super && 1
      end
    end

    assert_equal 1, @vehicle.park!
  end

  def test_should_not_allow_idle
    assert_sm_cannot_transition(@vehicle, :idle)
  end

  def test_should_allow_shift_up
    assert_sm_can_transition(@vehicle, :shift_up)
  end

  def test_should_not_allow_shift_down
    assert_sm_cannot_transition(@vehicle, :shift_down)
  end

  def test_should_not_allow_crash
    assert_sm_cannot_transition(@vehicle, :crash)
  end

  def test_should_not_allow_repair
    assert_sm_cannot_transition(@vehicle, :repair)
  end
end
