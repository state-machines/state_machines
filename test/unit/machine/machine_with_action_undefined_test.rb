require 'test_helper'

class MachineWithActionUndefinedTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, action: :save)
    @object = @klass.new
  end

  def test_should_define_an_event_attribute_reader
    assert @object.respond_to?(:state_event)
  end

  def test_should_define_an_event_attribute_writer
    assert @object.respond_to?(:state_event=)
  end

  def test_should_define_an_event_transition_attribute_reader
    assert @object.respond_to?(:state_event_transition, true)
  end

  def test_should_define_an_event_transition_attribute_writer
    assert @object.respond_to?(:state_event_transition=, true)
  end

  def test_should_not_define_action
    refute @object.respond_to?(:save)
  end

  def test_should_not_mark_action_hook_as_defined
    refute @machine.action_hook?
  end
end
