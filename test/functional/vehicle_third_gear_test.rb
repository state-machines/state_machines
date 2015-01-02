require_relative '../test_helper'
require_relative '../files/models/vehicle'

class VehicleThirdGearTest < MiniTest::Test
  def setup
    @vehicle = Vehicle.new
    @vehicle.ignite
    3.times { @vehicle.shift_up }
  end

  def test_should_be_in_third_gear_state
    assert_equal 'third_gear', @vehicle.state
  end

  def test_should_be_third_gear
    assert @vehicle.third_gear?
  end

  def test_should_not_allow_park
    refute @vehicle.park
  end

  def test_should_not_allow_idle
    refute @vehicle.idle
  end

  def test_should_not_allow_shift_up
    refute @vehicle.shift_up
  end

  def test_should_allow_shift_down
    assert @vehicle.shift_down
  end

  def test_should_allow_crash
    assert @vehicle.crash
  end

  def test_should_not_allow_repair
    refute @vehicle.repair
  end
end
