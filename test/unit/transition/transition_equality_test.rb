require_relative '../../test_helper'

class TransitionEqualityTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end

  def test_should_be_equal_with_same_properties
    transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    assert_equal transition, @transition
  end

  def test_should_not_be_equal_with_different_machines
    machine = StateMachines::Machine.new(@klass, :status, namespace: :other)
    machine.state :parked, :idling
    machine.event :ignite
    transition = StateMachines::Transition.new(@object, machine, :ignite, :parked, :idling)

    refute_equal transition, @transition
  end

  def test_should_not_be_equal_with_different_objects
    transition = StateMachines::Transition.new(@klass.new, @machine, :ignite, :parked, :idling)
    refute_equal transition, @transition
  end

  def test_should_not_be_equal_with_different_event_names
    @machine.event :park
    transition = StateMachines::Transition.new(@object, @machine, :park, :parked, :idling)
    refute_equal transition, @transition
  end

  def test_should_not_be_equal_with_different_from_state_names
    @machine.state :first_gear
    transition = StateMachines::Transition.new(@object, @machine, :ignite, :first_gear, :idling)
    refute_equal transition, @transition
  end

  def test_should_not_be_equal_with_different_to_state_names
    @machine.state :first_gear
    transition = StateMachines::Transition.new(@object, @machine, :ignite, :idling, :first_gear)
    refute_equal transition, @transition
  end
end
