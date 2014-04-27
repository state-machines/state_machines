require 'spec_helper'

describe Vehicle do
  let(:vehicle) { Vehicle.new }
  it 'should_not_allow_access_to_subclass_events' do
    expect(vehicle).respond_to?(:reverse)
  end

  it 'should_have_human_state_names' do
    expect(Vehicle.human_state_name(:parked)).to eq('parked')
  end

  it 'should_have_human_state_event_names' do
    expect(Vehicle.human_state_event_name(:park)).to eq('park')
  end

  context 'unsaved' do
    it 'should_be_in_parked_state' do
      expect(vehicle.state).to eq('parked')
    end
    it 'should_raise_exception_if_checking_invalid_state' do
      expect { vehicle.state?(:invalid) }.to raise_error(IndexError)
    end

    it 'should_raise_exception_if_getting_name_of_invalid_state' do
      vehicle.state ='invalid'
      expect { vehicle.state_name }.to raise_error(ArgumentError)
    end

    it 'should_be_parked' do
      expect(vehicle.parked?).to be_truthy
      expect(vehicle.state?(:parked)).to be_truthy
      expect(vehicle.state_name).to eq(:parked)
      expect(vehicle.human_state_name).to eq('parked')
    end

    it 'should_not_be_idling' do
      expect(vehicle.idling?).to be_falsy
    end

    it 'should_not_be_first_gear' do
      expect(vehicle.first_gear?).to be_falsy
    end

    it 'should_not_be_second_gear' do
      expect(vehicle.second_gear?).to be_falsy
    end

    it 'should_not_be_stalled' do
      expect(vehicle.stalled?).to be_falsy
    end

    it 'should_not_be_able_to_park' do
      expect(vehicle.can_park?).to be_falsy
    end


    it 'should_not_have_a_transition_for_park' do
      expect(vehicle.park_transition).to be_nil
    end


    it 'should_not_allow_park' do
      expect(vehicle.park).to be_falsy
    end

    it 'should_be_able_to_ignite' do
      expect(vehicle.can_ignite?).to be_truthy
    end

    it 'should_have_a_transition_for_ignite' do
      transition = vehicle.ignite_transition
      expect(transition).to_not be_nil
      expect(transition.from).to eq('parked')
      expect(transition.to).to eq('idling')
      expect(transition.event).to eq(:ignite)
      expect(transition.attribute).to eq(:state)
      expect(transition.object).to eq(vehicle)

    end

    it 'should_have_a_list_of_possible_events' do
      expect(vehicle.state_events).to eq([:ignite])
    end

    it 'should_have_a_list_of_possible_transitions' do
      expect(vehicle.state_transitions.map { |transition| transition.attributes }).to eq([{:object => vehicle, :attribute => :state, :event => :ignite, :from => 'parked', :to => 'idling'}])
    end

    it 'should_have_a_list_of_possible_paths' do
      expect(vehicle.state_paths(:to => :first_gear)).to eq([[
                                                                 StateMachines::Transition.new(vehicle, Vehicle.state_machine, :ignite, :parked, :idling),
                                                                 StateMachines::Transition.new(vehicle, Vehicle.state_machine, :shift_up, :idling, :first_gear)
                                                             ]])
    end

    it 'should_allow_generic_event_to_fire' do
      expect(vehicle.fire_state_event(:ignite)).to be_truthy
      expect(vehicle.state).to eq('idling')
    end

    it 'should_pass_arguments_through_to_generic_event_runner' do
      vehicle.fire_state_event(:ignite, 1, 2, 3)
      expect(vehicle.last_transition_args).to eq([1, 2, 3])
    end

    it 'should_allow_skipping_action_through_generic_event_runner' do
      vehicle.fire_state_event(:ignite, false)
      expect(vehicle.saved).to be_falsy
    end

    it 'should_raise_error_with_invalid_event_through_generic_event_runner' do
      expect { vehicle.fire_state_event(:invalid) }.to raise_error(IndexError)
    end

    it 'should_allow_ignite' do
      vehicle.ignite
      expect(vehicle.state).to eq('idling')
    end

    it 'should_allow_ignite_with_skipped_action' do
      expect(vehicle.ignite(false)).to be_truthy
      expect(vehicle.new_record?).to be_truthy
    end

    it 'should_allow_ignite_bang' do
      expect(vehicle.ignite!).to be_truthy
    end

    it 'should_allow_ignite_bang_with_skipped_action' do
      expect(vehicle.ignite!(false)).to be_truthy
      expect(vehicle.new_record?).to be_truthy
    end

    it 'should_be_saved_after_successful_event' do
      vehicle.ignite
      expect(vehicle.new_record?).to be_falsy
    end

    it 'should_not_allow_idle' do
      expect(vehicle.idle).to be_falsy
    end

    it 'should_not_allow_shift_down' do
      expect(vehicle.shift_down).to be_falsy
    end

    it 'should_not_allow_crash' do
      expect(vehicle.crash).to be_falsy
    end

    it 'should_not_allow_repair' do
      expect(vehicle.repair).to be_falsy
    end

    it 'should_be_insurance_inactive' do
      expect(vehicle.insurance_inactive?).to be_truthy
    end

    it 'should_be_able_to_buy' do
      expect(vehicle.can_buy_insurance?).to be_truthy
    end

    it 'should_allow_buying_insurance' do
      expect(vehicle.buy_insurance).to be_truthy
    end

    it 'should_allow_buying_insurance_bang' do
      expect(vehicle.buy_insurance!).to be_truthy
    end

    it 'should_allow_ignite_buying_insurance_with_skipped_action' do
      expect(vehicle.buy_insurance!(false)).to be_truthy
      expect(vehicle.new_record?).to be_truthy
    end

    it 'should_not_be_insurance_active' do
      expect(vehicle.insurance_active?).to be_falsy
    end

    it 'should_not_be_able_to_cancel' do
      expect(vehicle.can_cancel_insurance?).to be_falsy
    end

    it 'should_not_allow_cancelling_insurance' do
      expect(vehicle.cancel_insurance).to be_falsy
    end
  end

  context 'Parked' do

    it 'should_be_in_parked_state' do
      expect(vehicle.state).to eq('parked')
    end

    it 'should_not_have_the_seatbelt_on' do
      expect(vehicle.seatbelt_on).to be_falsy
    end

    it 'should_not_allow_park' do
      expect(vehicle.park).to be_falsy
    end

    it 'should_allow_ignite' do
      expect(vehicle.ignite).to be_truthy
      expect(vehicle.state).to eq('idling')
    end

    it 'should_not_allow_idle' do
      expect(vehicle.idle).to be_falsy
    end

    it 'should_not_allow_shift_up' do
      expect(vehicle.shift_up).to be_falsy
    end

    it 'should_not_allow_shift_down' do
      expect(vehicle.shift_down).to be_falsy
    end

    it 'should_not_allow_crash' do
      expect(vehicle.crash).to be_falsy
    end

    it 'should_not_allow_repair' do
      expect(vehicle.repair).to be_falsy
    end
#
#   it 'should_raise_exception_if_repair_not_allowed!' do
#     exception = assert_raise(StateMachines::InvalidTransition) {vehicle.repair!}
#     assert_equal vehicle, exception.object
#     assert_equal Vehicle.state_machine(:state), exception.machine
#     assert_equal :repair, exception.event
#     assert_equal'parked', exception.from
#   end
  end

  context 'Idling' do
    before(:each) do
      vehicle.ignite
    end

    it 'should_be_in_idling_state' do
      assert_equal 'idling', vehicle.state
    end

    it 'should_be_idling' do
      assert vehicle.idling?
    end

    it 'should_have_seatbelt_on' do
      assert vehicle.seatbelt_on
    end

    it 'should_track_time_elapsed' do
      assert_not_nil vehicle.time_elapsed
    end

    it 'should_allow_park' do
      assert vehicle.park
    end

    it 'should_call_park_with_bang_action' do
      class << vehicle
        def park
          super && 1
        end
      end

      assert_equal 1, vehicle.park!
    end

    it 'should_not_allow_idle' do
      assert !vehicle.idle
    end

    it 'should_allow_shift_up' do
      assert vehicle.shift_up
    end

    it 'should_not_allow_shift_down' do
      assert !vehicle.shift_down
    end

    it 'should_not_allow_crash' do
      assert !vehicle.crash
    end

    it 'should_not_allow_repair' do
      assert !vehicle.repair
    end
  end

  context 'Locked' do
    before(:each) do
      vehicle.state ='locked'
    end


    it 'should_be_parked_after_park' do
      vehicle.park
      expect(vehicle.parked?).to be_truthy
    end

    it 'should_be_parked_after_ignite' do
      vehicle.ignite
      expect(vehicle.parked?).to be_truthy
    end

    it 'should_be_parked_after_shift_up' do
      vehicle.shift_up
      expect(vehicle.parked?).to be_truthy
    end

    it 'should_be_parked_after_shift_down' do
      vehicle.shift_down
      expect(vehicle.parked?).to be_truthy
    end
  end

  context 'FirstGear' do
    before(:each) do

      vehicle.ignite
      vehicle.shift_up
    end

    it 'should_be_in_first_gear_state' do
      assert_equal 'first_gear', vehicle.state
    end

    it 'should_be_first_gear' do
      assert vehicle.first_gear?
    end

    it 'should_allow_park' do
      assert vehicle.park
    end

    it 'should_allow_idle' do
      assert vehicle.idle
    end

    it 'should_allow_shift_up' do
      assert vehicle.shift_up
    end

    it 'should_not_allow_shift_down' do
      assert !vehicle.shift_down
    end

    it 'should_allow_crash' do
      assert vehicle.crash
    end

    it 'should_not_allow_repair' do
      assert !vehicle.repair
    end
  end


  context 'SecondGear' do
    before(:each) do
      vehicle.ignite
      2.times { vehicle.shift_up }
    end

    it 'should_be_in_second_gear_state' do
      assert_equal 'second_gear', vehicle.state
    end

    it 'should_be_second_gear' do
      assert vehicle.second_gear?
    end

    it 'should_not_allow_park' do
      assert !vehicle.park
    end

    it 'should_not_allow_idle' do
      assert !vehicle.idle
    end

    it 'should_allow_shift_up' do
      assert vehicle.shift_up
    end

    it 'should_allow_shift_down' do
      assert vehicle.shift_down
    end

    it 'should_allow_crash' do
      assert vehicle.crash
    end

    it 'should_not_allow_repair' do
      assert !vehicle.repair
    end
  end

  context 'ThirdGear' do
    before(:each) do
      vehicle.ignite
      3.times { vehicle.shift_up }
    end

    it 'should_be_in_third_gear_state' do
      assert_equal 'third_gear', vehicle.state
    end

    it 'should_be_third_gear' do
      assert vehicle.third_gear?
    end

    it 'should_not_allow_park' do
      assert !vehicle.park
    end

    it 'should_not_allow_idle' do
      assert !vehicle.idle
    end

    it 'should_not_allow_shift_up' do
      assert !vehicle.shift_up
    end

    it 'should_allow_shift_down' do
      assert vehicle.shift_down
    end

    it 'should_allow_crash' do
      assert vehicle.crash
    end

    it 'should_not_allow_repair' do
      assert !vehicle.repair
    end
  end

  context 'Stalled' do
    before(:each) do
      vehicle.ignite
      vehicle.shift_up
      vehicle.crash
    end

    it 'should_be_in_stalled_state' do
      assert_equal 'stalled', vehicle.state
    end

    it 'should_be_stalled' do
      assert vehicle.stalled?
    end

    it 'should_be_towed' do
      assert vehicle.auto_shop.busy?
      assert_equal 1, vehicle.auto_shop.num_customers
    end

    it 'should_have_an_increased_insurance_premium' do
      assert_equal 150, vehicle.insurance_premium
    end

    it 'should_not_allow_park' do
      assert !vehicle.park
    end

    it 'should_allow_ignite' do
      assert vehicle.ignite
    end

    it 'should_not_change_state_when_ignited' do
      assert_equal 'stalled', vehicle.state
    end

    it 'should_not_allow_idle' do
      assert !vehicle.idle
    end

    it 'should_now_allow_shift_up' do
      assert !vehicle.shift_up
    end

    it 'should_not_allow_shift_down' do
      assert !vehicle.shift_down
    end

    it 'should_not_allow_crash' do
      assert !vehicle.crash
    end

    it 'should_allow_repair_if_auto_shop_is_busy' do
      assert vehicle.repair
    end

    it 'should_not_allow_repair_if_auto_shop_is_available' do
      vehicle.auto_shop.fix_vehicle
      assert !vehicle.repair
    end
  end

  context 'Repaired' do
    before(:each) do

      vehicle.ignite
      vehicle.shift_up
      vehicle.crash
      vehicle.repair
    end

    it 'should_be_in_parked_state' do
      assert_equal 'parked', vehicle.state
    end

    it 'should_not_have_a_busy_auto_shop' do
      assert vehicle.auto_shop.available?
    end
  end

  context 'Parallel events' do

    it 'should_fail_if_any_event_cannot_transition' do
      expect(vehicle.fire_events(:ignite, :cancel_insurance)).to be_falsy
    end

    it 'should_be_successful_if_all_events_transition' do
      expect(vehicle.fire_events(:ignite, :buy_insurance)).to be_truthy
    end

    it 'should_not_save_if_skipping_action' do
      expect(vehicle.fire_events(:ignite, :buy_insurance, false)).to be_truthy
      expect(vehicle.saved).to be_falsy
    end

    it 'should_raise_exception_if_any_event_cannot_transition_on_bang' do
      assert_raise(StateMachines::InvalidParallelTransition) { vehicle.fire_events!(:ignite, :cancel_insurance) }
      # assert_equal vehicle, exception.object
      # assert_equal [:ignite, :cancel_insurance], exception.events
    end

    it 'should_not_raise_exception_if_all_events_transition_on_bang' do
      expect(vehicle.fire_events!(:ignite, :buy_insurance)).to be_truthy
    end

    it 'should_not_save_if_skipping_action_on_bang' do
      expect(vehicle.fire_events!(:ignite, :buy_insurance, false)).to be_truthy
      expect(vehicle.saved).to be_falsy
    end
  end

  context 'Event attributes' do
    before(:each) do
      vehicle.state_event ='ignite'
    end


    it 'should_fail_if_event_is_invalid' do
      vehicle.state_event ='invalid'
      expect(vehicle.save).to be_falsy
      expect(vehicle.state).to eq('parked')
    end

    it 'should_fail_if_event_has_no_transition' do
      vehicle.state_event ='park'
      expect(vehicle.save).to be_falsy
      expect(vehicle.state).to eq('parked')
    end

    it 'should_return_original_action_value_on_success' do
      expect(vehicle.save).to eq(vehicle)
    end

    it 'should_transition_state_on_success' do
      vehicle.save
      expect(vehicle.state).to eq('idling')
    end
  end

end

