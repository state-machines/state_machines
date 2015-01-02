require_relative '../test_helper'
require_relative '../files/models/vehicle'

class VehicleUnsavedTest < MiniTest::Test
  def setup
    @vehicle = Vehicle.new
  end

  def test_should_be_in_parked_state
    assert_equal 'parked', @vehicle.state
  end

  def test_should_raise_exception_if_checking_invalid_state
    assert_raises(IndexError) { @vehicle.state?(:invalid) }
  end

  def test_should_raise_exception_if_getting_name_of_invalid_state
    @vehicle.state = 'invalid'
    assert_raises(ArgumentError) { @vehicle.state_name }
  end

  def test_should_be_parked
    assert @vehicle.parked?
    assert @vehicle.state?(:parked)
    assert_equal :parked, @vehicle.state_name
    assert_equal 'parked', @vehicle.human_state_name
  end

  def test_should_not_be_idling
    refute @vehicle.idling?
  end

  def test_should_not_be_first_gear
    refute @vehicle.first_gear?
  end

  def test_should_not_be_second_gear
    refute @vehicle.second_gear?
  end

  def test_should_not_be_stalled
    refute @vehicle.stalled?
  end

  def test_should_not_be_able_to_park
    refute @vehicle.can_park?
  end

  def test_should_not_have_a_transition_for_park
    assert_nil @vehicle.park_transition
  end

  def test_should_not_allow_park
    refute @vehicle.park
  end

  def test_should_be_able_to_ignite
    assert @vehicle.can_ignite?
  end

  def test_should_have_a_transition_for_ignite
    transition = @vehicle.ignite_transition
    refute_nil transition
    assert_equal 'parked', transition.from
    assert_equal 'idling', transition.to
    assert_equal :ignite, transition.event
    assert_equal :state, transition.attribute
    assert_equal @vehicle, transition.object
  end

  def test_should_have_a_list_of_possible_events
    assert_equal [:ignite], @vehicle.state_events
  end

  def test_should_have_a_list_of_possible_transitions
    assert_equal [{ object: @vehicle, attribute: :state, event: :ignite, from: 'parked', to: 'idling' }], @vehicle.state_transitions.map { |transition| transition.attributes }
  end

  def test_should_have_a_list_of_possible_paths
    assert_equal [[
      StateMachines::Transition.new(@vehicle, Vehicle.state_machine, :ignite, :parked, :idling),
      StateMachines::Transition.new(@vehicle, Vehicle.state_machine, :shift_up, :idling, :first_gear)
    ]], @vehicle.state_paths(to: :first_gear)
  end

  def test_should_allow_generic_event_to_fire
    assert @vehicle.fire_state_event(:ignite)
    assert_equal 'idling', @vehicle.state
  end

  def test_should_pass_arguments_through_to_generic_event_runner
    @vehicle.fire_state_event(:ignite, 1, 2, 3)
    assert_equal [1, 2, 3], @vehicle.last_transition_args
  end

  def test_should_allow_skipping_action_through_generic_event_runner
    @vehicle.fire_state_event(:ignite, false)
    assert_equal false, @vehicle.saved
  end

  def test_should_raise_error_with_invalid_event_through_generic_event_runer
    assert_raises(IndexError) { @vehicle.fire_state_event(:invalid) }
  end

  def test_should_allow_ignite
    assert @vehicle.ignite
    assert_equal 'idling', @vehicle.state
  end

  def test_should_allow_ignite_with_skipped_action
    assert @vehicle.ignite(false)
    assert @vehicle.new_record?
  end

  def test_should_allow_ignite_bang
    assert @vehicle.ignite!
  end

  def test_should_allow_ignite_bang_with_skipped_action
    assert @vehicle.ignite!(false)
    assert @vehicle.new_record?
  end

  def test_should_be_saved_after_successful_event
    @vehicle.ignite
    refute @vehicle.new_record?
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

  def test_should_be_insurance_inactive
    assert @vehicle.insurance_inactive?
  end

  def test_should_be_able_to_buy
    assert @vehicle.can_buy_insurance?
  end

  def test_should_allow_buying_insurance
    assert @vehicle.buy_insurance
  end

  def test_should_allow_buying_insurance_bang
    assert @vehicle.buy_insurance!
  end

  def test_should_allow_ignite_buying_insurance_with_skipped_action
    assert @vehicle.buy_insurance!(false)
    assert @vehicle.new_record?
  end

  def test_should_not_be_insurance_active
    refute @vehicle.insurance_active?
  end

  def test_should_not_be_able_to_cancel
    refute @vehicle.can_cancel_insurance?
  end

  def test_should_not_allow_cancelling_insurance
    refute @vehicle.cancel_insurance
  end
end
