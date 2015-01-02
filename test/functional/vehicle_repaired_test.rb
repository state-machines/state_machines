require_relative '../test_helper'
require_relative '../files/models/vehicle'

class VehicleRepairedTest < MiniTest::Test
  def setup
    @vehicle = Vehicle.new
    @vehicle.ignite
    @vehicle.shift_up
    @vehicle.crash
    @vehicle.repair
  end

  def test_should_be_in_parked_state
    assert_equal 'parked', @vehicle.state
  end

  def test_should_not_have_a_busy_auto_shop
    assert @vehicle.auto_shop.available?
  end
end
