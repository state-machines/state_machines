require_relative '../test_helper'
require_relative '../files/models/vehicle'

class VehicleTest < MiniTest::Test
  def setup
    @vehicle = Vehicle.new
  end

  def test_should_not_allow_access_to_subclass_events
    refute @vehicle.respond_to?(:reverse)
  end

  def test_should_have_human_state_names
    assert_equal 'parked', Vehicle.human_state_name(:parked)
  end

  def test_should_have_human_state_event_names
    assert_equal 'park', Vehicle.human_state_event_name(:park)
  end
end
