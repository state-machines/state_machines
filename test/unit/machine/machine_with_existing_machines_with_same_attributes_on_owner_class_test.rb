require_relative '../../test_helper'

class MachineWithExistingMachinesWithSameAttributesOnOwnerClassTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @second_machine = StateMachines::Machine.new(@klass, :public_state, initial: :idling, attribute: :state)
    @object = @klass.new
  end

  def test_should_track_each_state_machine
    expected = { state: @machine, public_state: @second_machine }
    assert_equal expected, @klass.state_machines
  end

  def test_should_write_to_state_only_once
    @klass.class_eval do
      attr_reader :write_count

      def state=(_value)
        @write_count ||= 0
        @write_count += 1
      end
    end
    object = @klass.new

    assert_equal 1, object.write_count
  end

  def test_should_initialize_based_on_first_machine
    assert_equal 'parked', @object.state
  end

  def test_should_not_allow_second_machine_to_initialize_state
    @object.state = nil
    @second_machine.initialize_state(@object)
    assert_nil @object.state
  end

  def test_should_allow_transitions_on_both_machines
    @machine.event :ignite do
      transition parked: :idling
    end

    @second_machine.event :park do
      transition idling: :parked
    end

    @object.ignite
    assert_equal 'idling', @object.state

    @object.park
    assert_equal 'parked', @object.state
  end

  def test_should_copy_new_states_to_sibling_machines
    @first_gear = @machine.state :first_gear
    assert_equal @first_gear, @second_machine.state(:first_gear)

    @second_gear = @second_machine.state :second_gear
    assert_equal @second_gear, @machine.state(:second_gear)
  end

  def test_should_copy_all_existing_states_to_new_machines
    third_machine = StateMachines::Machine.new(@klass, :protected_state, attribute: :state)

    assert_equal @machine.state(:parked), third_machine.state(:parked)
    assert_equal @machine.state(:idling), third_machine.state(:idling)
  end
end

