require_relative '../test_helper'
require_relative '../files/models/vehicle'

class VehicleWithParallelEventsTest < MiniTest::Test
  def setup
    @vehicle = Vehicle.new
  end

  def test_should_fail_if_any_event_cannot_transition
    refute @vehicle.fire_events(:ignite, :cancel_insurance)
  end

  def test_should_be_successful_if_all_events_transition
    assert @vehicle.fire_events(:ignite, :buy_insurance)
  end

  def test_should_not_save_if_skipping_action
    assert @vehicle.fire_events(:ignite, :buy_insurance, false)
    refute @vehicle.saved
  end

  def test_should_raise_exception_if_any_event_cannot_transition_on_bang
    exception = assert_raises(StateMachines::InvalidParallelTransition) { @vehicle.fire_events!(:ignite, :cancel_insurance) }
    assert_equal @vehicle, exception.object
    assert_equal [:ignite, :cancel_insurance], exception.events
  end

  def test_should_not_raise_exception_if_all_events_transition_on_bang
    assert @vehicle.fire_events!(:ignite, :buy_insurance)
  end

  def test_should_not_save_if_skipping_action_on_bang
    assert @vehicle.fire_events!(:ignite, :buy_insurance, false)
    refute @vehicle.saved
  end
end
