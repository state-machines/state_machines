require_relative '../../test_helper'

class InvalidTransitionWithNamespaceTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, namespace: 'alarm')
    @state = @machine.state :active
    @machine.event :disable

    @object = @klass.new
    @object.state = 'active'

    @invalid_transition = StateMachines::InvalidTransition.new(@object, @machine, :disable)
  end

  def test_should_have_an_event
    assert_equal :disable, @invalid_transition.event
  end

  def test_should_have_a_qualified_event
    assert_equal :disable_alarm, @invalid_transition.qualified_event
  end

  def test_should_have_a_from_name
    assert_equal :active, @invalid_transition.from_name
  end

  def test_should_have_a_qualified_from_name
    assert_equal :alarm_active, @invalid_transition.qualified_from_name
  end
end

