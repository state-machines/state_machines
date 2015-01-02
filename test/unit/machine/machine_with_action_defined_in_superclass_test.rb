require_relative '../../test_helper'

class MachineWithActionDefinedInSuperclassTest < StateMachinesTest
  def setup
    @superclass = Class.new do
      def save
      end
    end
    @klass = Class.new(@superclass)

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

  def test_should_define_action
    assert @klass.ancestors.any? { |ancestor| ![@klass, @superclass].include?(ancestor) && ancestor.method_defined?(:save) }
  end

  def test_should_keep_action_public
    assert @klass.public_method_defined?(:save)
  end

  def test_should_mark_action_hook_as_defined
    assert @machine.action_hook?
  end
end

