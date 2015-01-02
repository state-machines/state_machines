require_relative '../test_helper'
require_relative '../files/models/motorcycle'

class MotorcycleTest < MiniTest::Test
  def setup
    @motorcycle = Motorcycle.new
  end

  def test_should_be_in_idling_state
    assert_equal 'idling', @motorcycle.state
  end

  def test_should_allow_park
    assert @motorcycle.park
  end

  def test_should_not_allow_ignite
    refute @motorcycle.ignite
  end

  def test_should_allow_shift_up
    assert @motorcycle.shift_up
  end

  def test_should_not_allow_shift_down
    refute @motorcycle.shift_down
  end

  def test_should_not_allow_crash
    refute @motorcycle.crash
  end

  def test_should_not_allow_repair
    refute @motorcycle.repair
  end

  def test_should_inherit_decibels_from_superclass
    @motorcycle.park
    assert_equal 0.0, @motorcycle.decibels
  end

  def test_should_use_decibels_defined_in_state
    @motorcycle.shift_up
    assert_equal 1.0, @motorcycle.decibels
  end
end
