# frozen_string_literal: true

require 'test_helper'
require 'files/models/car'

class CarTest < StateMachinesTest
  def setup
    @car = Car.new
  end

  def test_should_be_in_parked_state
    assert_sm_state(@car, :parked)
  end

  def test_should_not_have_the_seatbelt_on
    refute @car.seatbelt_on
  end

  def test_should_not_allow_park
    assert_sm_cannot_transition(@car, :park)
  end

  def test_should_allow_ignite
    assert_sm_transition(@car, :ignite, :idling)
  end

  def test_should_not_allow_idle
    assert_sm_cannot_transition(@car, :idle)
  end

  def test_should_not_allow_shift_up
    assert_sm_cannot_transition(@car, :shift_up)
  end

  def test_should_not_allow_shift_down
    assert_sm_cannot_transition(@car, :shift_down)
  end

  def test_should_not_allow_crash
    assert_sm_cannot_transition(@car, :crash)
  end

  def test_should_not_allow_repair
    assert_sm_cannot_transition(@car, :repair)
  end

  def test_should_allow_reverse
    assert_sm_can_transition(@car, :reverse)
  end
end
