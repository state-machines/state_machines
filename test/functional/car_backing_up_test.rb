require_relative '../test_helper'
require_relative '../files/models/car'

class CarBackingUpTest < MiniTest::Test
  def setup
    @car = Car.new
    @car.reverse
  end

  def test_should_be_in_backing_up_state
    assert_equal 'backing_up', @car.state
  end

  def test_should_allow_park
    assert @car.park
  end

  def test_should_not_allow_ignite
    refute @car.ignite
  end

  def test_should_allow_idle
    assert @car.idle
  end

  def test_should_allow_shift_up
    assert @car.shift_up
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

  def test_should_not_allow_reverse
    refute @car.reverse
  end
end
