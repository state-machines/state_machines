require_relative '../../test_helper'

class TransitionWithNamespaceTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, namespace: 'alarm')
    @machine.state :off, :active
    @machine.event :activate

    @object = @klass.new
    @object.state = 'off'

    @transition = StateMachines::Transition.new(@object, @machine, :activate, :off, :active)
  end

  def test_should_have_an_event
    assert_equal :activate, @transition.event
  end

  def test_should_have_a_qualified_event
    assert_equal :activate_alarm, @transition.qualified_event
  end

  def test_should_have_a_from_name
    assert_equal :off, @transition.from_name
  end

  def test_should_have_a_qualified_from_name
    assert_equal :alarm_off, @transition.qualified_from_name
  end

  def test_should_have_a_human_from_name
    assert_equal 'off', @transition.human_from_name
  end

  def test_should_have_a_to_name
    assert_equal :active, @transition.to_name
  end

  def test_should_have_a_qualified_to_name
    assert_equal :alarm_active, @transition.qualified_to_name
  end

  def test_should_have_a_human_to_name
    assert_equal 'active', @transition.human_to_name
  end
end
