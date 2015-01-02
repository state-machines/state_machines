require_relative '../test_helper'
require_relative '../files/models/auto_shop'

class AutoShopBusyTest < MiniTest::Test
  def setup
    @auto_shop = AutoShop.new
    @auto_shop.tow_vehicle
  end

  def test_should_be_in_busy_state
    assert_equal 'busy', @auto_shop.state
  end

  def test_should_have_incremented_number_of_customers
    assert_equal 1, @auto_shop.num_customers
  end

  def test_should_not_allow_tow_vehicle
    refute @auto_shop.tow_vehicle
  end

  def test_should_allow_fix_vehicle
    assert @auto_shop.fix_vehicle
  end
end
