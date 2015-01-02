require_relative '../test_helper'
require_relative '../files/models/car'

class CarTest < MiniTest::Test
  def setup
    @car = Car.new
  end

  def test_should_be_in_parked_state
    assert_equal 'parked', @car.state
  end

  def test_should_not_have_the_seatbelt_on
    refute @car.seatbelt_on
  end

  def test_should_not_allow_park
    refute @car.park
  end

  def test_should_allow_ignite
    assert @car.ignite
    assert_equal 'idling', @car.state
  end

  def test_should_not_allow_idle
    refute @car.idle
  end

  def test_should_not_allow_shift_up
    refute @car.shift_up
  end

  def test_should_not_allow_shift_down
    refute @car.shift_down
  end

  def test_should_not_allow_crash
    refute @car.crash
  end

  def test_should_not_allow_repair
    refute @car.repair
  end

  def test_should_allow_reverse
    assert @car.reverse
  end
end
