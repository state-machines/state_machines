require_relative '../../test_helper'

class MachineByDefaultTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @object = @klass.new
  end

  def test_should_have_an_owner_class
    assert_equal @klass, @machine.owner_class
  end

  def test_should_have_a_name
    assert_equal :state, @machine.name
  end

  def test_should_have_an_attribute
    assert_equal :state, @machine.attribute
  end

  def test_should_prefix_custom_attributes_with_attribute
    assert_equal :state_event, @machine.attribute(:event)
  end

  def test_should_have_an_initial_state
    refute_nil @machine.initial_state(@object)
  end

  def test_should_have_a_nil_initial_state
    assert_nil @machine.initial_state(@object).value
  end

  def test_should_not_have_any_events
    refute @machine.events.any?
  end

  def test_should_not_have_any_before_callbacks
    assert @machine.callbacks[:before].empty?
  end

  def test_should_not_have_any_after_callbacks
    assert @machine.callbacks[:after].empty?
  end

  def test_should_not_have_any_failure_callbacks
    assert @machine.callbacks[:failure].empty?
  end

  def test_should_not_have_an_action
    assert_nil @machine.action
  end

  def test_should_use_tranactions
    assert_equal true, @machine.use_transactions
  end

  def test_should_not_have_a_namespace
    assert_nil @machine.namespace
  end

  def test_should_have_a_nil_state
    assert_equal [nil], @machine.states.keys
  end

  def test_should_set_initial_on_nil_state
    assert @machine.state(nil).initial
  end

  def test_should_generate_default_messages
    assert_equal 'is invalid', @machine.generate_message(:invalid)
    assert_equal 'cannot transition when parked', @machine.generate_message(:invalid_event, [[:state, :parked]])
    assert_equal 'cannot transition via "park"', @machine.generate_message(:invalid_transition, [[:event, :park]])
  end

  def test_should_define_a_reader_attribute_for_the_attribute
    assert @object.respond_to?(:state)
  end

  def test_should_define_a_writer_attribute_for_the_attribute
    assert @object.respond_to?(:state=)
  end

  def test_should_define_a_predicate_for_the_attribute
    assert @object.respond_to?(:state?)
  end

  def test_should_define_a_name_reader_for_the_attribute
    assert @object.respond_to?(:state_name)
  end

  def test_should_define_an_event_reader_for_the_attribute
    assert @object.respond_to?(:state_events)
  end

  def test_should_define_a_transition_reader_for_the_attribute
    assert @object.respond_to?(:state_transitions)
  end

  def test_should_define_a_path_reader_for_the_attribute
    assert @object.respond_to?(:state_paths)
  end

  def test_should_define_an_event_runner_for_the_attribute
    assert @object.respond_to?(:fire_state_event)
  end

  def test_should_not_define_an_event_attribute_reader
    refute @object.respond_to?(:state_event)
  end

  def test_should_not_define_an_event_attribute_writer
    refute @object.respond_to?(:state_event=)
  end

  def test_should_not_define_an_event_transition_attribute_reader
    refute @object.respond_to?(:state_event_transition)
  end

  def test_should_not_define_an_event_transition_attribute_writer
    refute @object.respond_to?(:state_event_transition=)
  end

  def test_should_define_a_human_attribute_name_reader_for_the_attribute
    assert @klass.respond_to?(:human_state_name)
  end

  def test_should_define_a_human_event_name_reader_for_the_attribute
    assert @klass.respond_to?(:human_state_event_name)
  end

  def test_should_not_define_singular_with_scope
    refute @klass.respond_to?(:with_state)
  end

  def test_should_not_define_singular_without_scope
    refute @klass.respond_to?(:without_state)
  end

  def test_should_not_define_plural_with_scope
    refute @klass.respond_to?(:with_states)
  end

  def test_should_not_define_plural_without_scope
    refute @klass.respond_to?(:without_states)
  end

  def test_should_extend_owner_class_with_class_methods
    assert((class << @klass; ancestors; end).include?(StateMachines::ClassMethods))
  end

  def test_should_include_instance_methods_in_owner_class
    assert @klass.included_modules.include?(StateMachines::InstanceMethods)
  end

  def test_should_define_state_machines_reader
    expected = { state: @machine }
    assert_equal expected, @klass.state_machines
  end
end
