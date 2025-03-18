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
    assert @vehicle.parked?
  end

  def test_should_be_parked_after_ignite
    @vehicle.ignite
    assert @vehicle.parked?
  end

  def test_should_be_parked_after_shift_up
    @vehicle.shift_up
    assert @vehicle.parked?
  end

  def test_should_be_parked_after_shift_down
    @vehicle.shift_down
    assert @vehicle.parked?
  end
end
