# frozen_string_literal: true

require 'test_helper'
require 'files/models/vehicle'

class VehicleWithParallelEventsTest < StateMachinesTest
  def setup
    @vehicle = Vehicle.new
  end

  def test_should_fail_if_any_event_cannot_transition
    # Cannot cancel insurance when inactive
    assert_sm_cannot_transition(@vehicle, :cancel_insurance, machine_name: :insurance_state)
    refute @vehicle.fire_events(:ignite, :cancel_insurance)
  end

  def test_should_be_successful_if_all_events_transition
    # Both events should be possible
    assert_sm_can_transition(@vehicle, :ignite)
    assert_sm_can_transition(@vehicle, :buy_insurance, machine_name: :insurance_state)
    assert @vehicle.fire_events(:ignite, :buy_insurance)

    # Verify final states on both machines
    assert_sm_state(@vehicle, :idling)
    assert_sm_state(@vehicle, :active, machine_name: :insurance_state)
  end

  def test_should_not_save_if_skipping_action
    assert @vehicle.fire_events(:ignite, :buy_insurance, false)
    refute @vehicle.saved

    # States should still have changed even without saving
    assert_sm_state(@vehicle, :idling)
    assert_sm_state(@vehicle, :active, machine_name: :insurance_state)
  end

  def test_should_raise_exception_if_any_event_cannot_transition_on_bang
    # Use TestHelper to verify preconditions
    assert_sm_can_transition(@vehicle, :ignite)
    assert_sm_cannot_transition(@vehicle, :cancel_insurance, machine_name: :insurance_state)

    exception = assert_raises(StateMachines::InvalidParallelTransition) { @vehicle.fire_events!(:ignite, :cancel_insurance) }
    assert_equal @vehicle, exception.object
    assert_equal %i[ignite cancel_insurance], exception.events
  end

  def test_should_not_raise_exception_if_all_events_transition_on_bang
    # Verify both transitions are possible before attempting
    assert_sm_can_transition(@vehicle, :ignite)
    assert_sm_can_transition(@vehicle, :buy_insurance, machine_name: :insurance_state)

    assert @vehicle.fire_events!(:ignite, :buy_insurance)

    # Verify final states using TestHelper
    assert_sm_state(@vehicle, :idling)
    assert_sm_state(@vehicle, :active, machine_name: :insurance_state)
  end

  def test_should_not_save_if_skipping_action_on_bang
    assert @vehicle.fire_events!(:ignite, :buy_insurance, false)
    refute @vehicle.saved

    # Use multi-FSM assertions to verify both state changes
    assert_sm_state(@vehicle, :idling)
    assert_sm_state(@vehicle, :active, machine_name: :insurance_state)
  end
end
