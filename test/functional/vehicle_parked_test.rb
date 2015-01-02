require_relative '../test_helper'
require_relative '../files/models/vehicle'

class VehicleParkedTest < MiniTest::Test
  def setup
    @vehicle = Vehicle.new
  end

  def test_should_be_in_parked_state
    assert_equal 'parked', @vehicle.state
  end

  def test_should_not_have_the_seatbelt_on
    refute @vehicle.seatbelt_on
  end

  def test_should_not_allow_park
    refute @vehicle.park
  end

  def test_should_allow_ignite
    assert @vehicle.ignite
    assert_equal 'idling', @vehicle.state
  end

  def test_should_not_allow_idle
    refute @vehicle.idle
  end

  def test_should_not_allow_shift_up
    refute @vehicle.shift_up
  end

  def test_should_not_allow_shift_down
    refute @vehicle.shift_down
  end

  def test_should_not_allow_crash
    refute @vehicle.crash
  end

  def test_should_not_allow_repair
    refute @vehicle.repair
  end

  def test_should_raise_exception_if_repair_not_allowed!
    exception = assert_raises(StateMachines::InvalidTransition) { @vehicle.repair! }
    assert_equal @vehicle, exception.object
    assert_equal Vehicle.state_machine(:state), exception.machine
    assert_equal :repair, exception.event
    assert_equal 'parked', exception.from
  end
end
