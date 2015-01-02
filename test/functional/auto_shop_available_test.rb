require_relative '../test_helper'
require_relative '../files/models/auto_shop'

class AutoShopAvailableTest < MiniTest::Test
  def setup
    @auto_shop = AutoShop.new
  end

  def test_should_be_in_available_state
    assert_equal 'available', @auto_shop.state
  end

  def test_should_allow_tow_vehicle
    assert @auto_shop.tow_vehicle
  end

  def test_should_not_allow_fix_vehicle
    refute @auto_shop.fix_vehicle
  end
end
