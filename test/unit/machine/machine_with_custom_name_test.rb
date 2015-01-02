require_relative '../../test_helper'

class MachineWithCustomNameTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, :status)
    @object = @klass.new
  end

  def test_should_use_custom_name
    assert_equal :status, @machine.name
  end

  def test_should_use_custom_name_for_attribute
    assert_equal :status, @machine.attribute
  end

  def test_should_prefix_custom_attributes_with_custom_name
    assert_equal :status_event, @machine.attribute(:event)
  end

  def test_should_define_a_reader_attribute_for_the_attribute
    assert @object.respond_to?(:status)
  end

  def test_should_define_a_writer_attribute_for_the_attribute
    assert @object.respond_to?(:status=)
  end

  def test_should_define_a_predicate_for_the_attribute
    assert @object.respond_to?(:status?)
  end

  def test_should_define_a_name_reader_for_the_attribute
    assert @object.respond_to?(:status_name)
  end

  def test_should_define_an_event_reader_for_the_attribute
    assert @object.respond_to?(:status_events)
  end

  def test_should_define_a_transition_reader_for_the_attribute
    assert @object.respond_to?(:status_transitions)
  end

  def test_should_define_an_event_runner_for_the_attribute
    assert @object.respond_to?(:fire_status_event)
  end

  def test_should_define_a_human_attribute_name_reader_for_the_attribute
    assert @klass.respond_to?(:human_status_name)
  end

  def test_should_define_a_human_event_name_reader_for_the_attribute
    assert @klass.respond_to?(:human_status_event_name)
  end
end
