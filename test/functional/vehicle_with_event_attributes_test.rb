require_relative '../test_helper'
require_relative '../files/models/vehicle'

class VehicleWithEventAttributesTest < MiniTest::Test
  def setup
    @vehicle = Vehicle.new
    @vehicle.state_event = 'ignite'
  end

  def test_should_fail_if_event_is_invalid
    @vehicle.state_event = 'invalid'
    refute @vehicle.save
    assert_equal 'parked', @vehicle.state
  end

  def test_should_fail_if_event_has_no_transition
    @vehicle.state_event = 'park'
    refute @vehicle.save
    assert_equal 'parked', @vehicle.state
  end

  def test_should_return_original_action_value_on_success
    assert_equal @vehicle, @vehicle.save
  end

  def test_should_transition_state_on_success
    @vehicle.save
    assert_equal 'idling', @vehicle.state
  end
end
