require_relative '../test_helper'
require_relative '../files/models/vehicle'

class VehicleStalledTest < MiniTest::Test
  def setup
    @vehicle = Vehicle.new
    @vehicle.ignite
    @vehicle.shift_up
    @vehicle.crash
  end

  def test_should_be_in_stalled_state
    assert_equal 'stalled', @vehicle.state
  end

  def test_should_be_stalled
    assert @vehicle.stalled?
  end

  def test_should_be_towed
    assert @vehicle.auto_shop.busy?
    assert_equal 1, @vehicle.auto_shop.num_customers
  end

  def test_should_have_an_increased_insurance_premium
    assert_equal 150, @vehicle.insurance_premium
  end

  def test_should_not_allow_park
    refute @vehicle.park
  end

  def test_should_allow_ignite
    assert @vehicle.ignite
  end

  def test_should_not_change_state_when_ignited
    assert_equal 'stalled', @vehicle.state
  end

  def test_should_not_allow_idle
    refute @vehicle.idle
  end

  def test_should_now_allow_shift_up
    refute @vehicle.shift_up
  end

  def test_should_not_allow_shift_down
    refute @vehicle.shift_down
  end

  def test_should_not_allow_crash
    refute @vehicle.crash
  end

  def test_should_allow_repair_if_auto_shop_is_busy
    assert @vehicle.repair
  end

  def test_should_not_allow_repair_if_auto_shop_is_available
    @vehicle.auto_shop.fix_vehicle
    refute @vehicle.repair
  end
end
