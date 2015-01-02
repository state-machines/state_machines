require_relative '../test_helper'
require_relative '../files/models/vehicle'

class VehicleSecondGearTest < MiniTest::Test
  def setup
    @vehicle = Vehicle.new
    @vehicle.ignite
    2.times { @vehicle.shift_up }
  end

  def test_should_be_in_second_gear_state
    assert_equal 'second_gear', @vehicle.state
  end

  def test_should_be_second_gear
    assert @vehicle.second_gear?
  end

  def test_should_not_allow_park
    refute @vehicle.park
  end

  def test_should_not_allow_idle
    refute @vehicle.idle
  end

  def test_should_allow_shift_up
    assert @vehicle.shift_up
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
