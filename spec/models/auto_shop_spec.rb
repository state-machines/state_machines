require 'spec_helper'

describe AutoShop do

  let(:auto_shop) { AutoShop.new }

  it 'should_be_in_available_state' do
    assert_equal 'available', auto_shop.state
  end

  it 'should_allow_tow_vehicle' do
    assert auto_shop.tow_vehicle
  end

  it 'should_not_allow_fix_vehicle' do
    assert !auto_shop.fix_vehicle
  end

  context 'Busy' do
    before(:each) do
      auto_shop.tow_vehicle
    end

    it 'should_be_in_busy_state' do
      assert_equal 'busy', auto_shop.state
    end

    it 'should_have_incremented_number_of_customers' do
      assert_equal 1, auto_shop.num_customers
    end

    it 'should_not_allow_tow_vehicle' do
      assert !auto_shop.tow_vehicle
    end

    it 'should_allow_fix_vehicle' do
      assert auto_shop.fix_vehicle
    end
  end

end
