# frozen_string_literal: true

require 'test_helper'

class EventWithNamespaceTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, namespace: 'alarm')
    @machine.events << @event = StateMachines::Event.new(@machine, :enable)
    @object = @klass.new
  end

  def test_should_have_a_name
    assert_equal :enable, @event.name
  end

  def test_should_have_a_qualified_name
    assert_equal :enable_alarm, @event.qualified_name
  end

  def test_should_namespace_predicate
    assert_respond_to @object, :can_enable_alarm?
  end

  def test_should_namespace_transition_accessor
    assert_respond_to @object, :enable_alarm_transition
  end

  def test_should_namespace_action
    assert_respond_to @object, :enable_alarm
  end

  def test_should_namespace_bang_action
    assert_respond_to @object, :enable_alarm!
  end
end
