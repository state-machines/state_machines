require 'spec_helper'

describe Car do
  let(:car) { Car.new }

  it 'should_be_in_parked_state' do
    assert_equal 'parked', car.state
  end

  it 'should_not_have_the_seatbelt_on' do
    assert !car.seatbelt_on
  end

  it 'should_not_allow_park' do
    assert !car.park
  end

  it 'should_allow_ignite' do
    assert car.ignite
    assert_equal 'idling', car.state
  end

  it 'should_not_allow_idle' do
    assert !car.idle
  end

  it 'should_not_allow_shift_up' do
    assert !car.shift_up
  end

  it 'should_not_allow_shift_down' do
    assert !car.shift_down
  end

  it 'should_not_allow_crash' do
    assert !car.crash
  end

  it 'should_not_allow_repair' do
    assert !car.repair
  end

  it 'should_allow_reverse' do
    assert car.reverse
  end


  context 'backing up' do
    before(:each) do
      car.reverse
    end

    it 'should_be_in_backing_up_state' do
      assert_equal 'backing_up', car.state
    end

    it 'should_allow_park' do
      assert car.park
    end

    it 'should_not_allow_ignite' do
      assert !car.ignite
    end

    it 'should_allow_idle' do
      assert car.idle
    end

    it 'should_allow_shift_up' do
      assert car.shift_up
    end

    it 'should_not_allow_shift_down' do
      assert !car.shift_down
    end

    it 'should_not_allow_crash' do
      assert !car.crash
    end

    it 'should_not_allow_repair' do
      assert !car.repair
    end

    it 'should_not_allow_reverse' do
      assert !car.reverse
    end

  end
end
