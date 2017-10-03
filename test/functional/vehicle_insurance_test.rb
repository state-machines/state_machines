require_relative '../test_helper'
require_relative '../files/models/vehicle'

class VehicleInsuranceTest < MiniTest::Test
  def setup
    @vehicle = Vehicle.new
  end

  def test_insurance_state_should_be_in_inactive_state
    assert_equal 'inactive', @vehicle.insurance_state
  end

  def test_insurance_should_be_inactive
    assert @vehicle.insurance_inactive?
  end

  def test_should_allow_buy_insurance
    assert @vehicle.buy_insurance
  end

  def test_insurance_should_be_active_after_buy_event
    @vehicle.buy_insurance
    assert @vehicle.insurance_active?
  end
end
