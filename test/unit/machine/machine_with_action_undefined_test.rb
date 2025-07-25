# frozen_string_literal: true

require 'test_helper'

class MachineWithActionUndefinedTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, action: :save)
    @object = @klass.new
  end

  def test_should_define_an_event_attribute_reader
    assert_respond_to @object, :state_event
  end

  def test_should_define_an_event_attribute_writer
    assert_respond_to @object, :state_event=
  end

  def test_should_define_an_event_transition_attribute_reader
    assert @object.respond_to?(:state_event_transition, true)
  end

  def test_should_define_an_event_transition_attribute_writer
    assert @object.respond_to?(:state_event_transition=, true)
  end

  def test_should_not_define_action
    refute_respond_to @object, :save
  end

  def test_should_not_mark_action_hook_as_defined
    refute_predicate @machine, :action_hook?
  end
end
