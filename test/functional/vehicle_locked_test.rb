# frozen_string_literal: true

require 'test_helper'
require 'files/models/vehicle'

class VehicleLockedTest < Minitest::Test
  def setup
    @vehicle = Vehicle.new
    @vehicle.state = 'locked'
  end

  def test_should_be_parked_after_park
    @vehicle.park

    assert_predicate @vehicle, :parked?
  end

  def test_should_be_parked_after_ignite
    @vehicle.ignite

    assert_predicate @vehicle, :parked?
  end

  def test_should_be_parked_after_shift_up
    @vehicle.shift_up

    assert_predicate @vehicle, :parked?
  end

  def test_should_be_parked_after_shift_down
    @vehicle.shift_down

    assert_predicate @vehicle, :parked?
  end
end
