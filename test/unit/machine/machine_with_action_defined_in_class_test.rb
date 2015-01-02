require_relative '../../test_helper'

class MachineWithActionDefinedInClassTest < StateMachinesTest
  def setup
    @klass = Class.new do
      def save
      end
    end

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
    refute @klass.ancestors.any? { |ancestor| ancestor != @klass && ancestor.method_defined?(:save) }
  end

  def test_should_not_mark_action_hook_as_defined
    refute @machine.action_hook?
  end
end
