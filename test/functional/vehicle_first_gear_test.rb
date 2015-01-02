require_relative '../test_helper'
require_relative '../files/models/vehicle'

class VehicleFirstGearTest < MiniTest::Test
  def setup
    @vehicle = Vehicle.new
    @vehicle.ignite
    @vehicle.shift_up
  end

  def test_should_be_in_first_gear_state
    assert_equal 'first_gear', @vehicle.state
  end

  def test_should_be_first_gear
    assert @vehicle.first_gear?
  end

  def test_should_allow_park
    assert @vehicle.park
  end

  def test_should_allow_idle
    assert @vehicle.idle
  end

  def test_should_allow_shift_up
    assert @vehicle.shift_up
  end

  def test_should_not_allow_shift_down
    refute @vehicle.shift_down
  end

  def test_should_allow_crash
    assert @vehicle.crash
  end

  def test_should_not_allow_repair
    refute @vehicle.repair
  end
end
