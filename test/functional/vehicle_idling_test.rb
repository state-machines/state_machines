require_relative '../test_helper'
require_relative '../files/models/vehicle'

class VehicleIdlingTest < MiniTest::Test
  def setup
    @vehicle = Vehicle.new
    @vehicle.ignite
  end

  def test_should_be_in_idling_state
    assert_equal 'idling', @vehicle.state
  end

  def test_should_be_idling
    assert @vehicle.idling?
  end

  def test_should_have_seatbelt_on
    assert @vehicle.seatbelt_on
  end

  def test_should_track_time_elapsed
    refute_nil @vehicle.time_elapsed
  end

  def test_should_allow_park
    assert @vehicle.park
  end

  def test_should_call_park_with_bang_action
    class << @vehicle
      def park
        super && 1
      end
    end

    assert_equal 1, @vehicle.park!
  end

  def test_should_not_allow_idle
    refute @vehicle.idle
  end

  def test_should_allow_shift_up
    assert @vehicle.shift_up
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
end
