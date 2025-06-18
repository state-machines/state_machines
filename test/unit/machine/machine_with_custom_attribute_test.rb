# frozen_string_literal: true

require 'test_helper'

module MachineWithCustomAttributeIntegration
  include StateMachines::Integrations::Base

  def self.integration_name
    :custom_attribute
  end

  @defaults = { action: :save, use_transactions: false }

  def create_with_scope(_name)
    -> {}
  end

  def create_without_scope(_name)
    -> {}
  end
end

class MachineWithCustomAttributeTest < StateMachinesTest
  def setup
    StateMachines::Integrations.register(MachineWithCustomAttributeIntegration)

    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, :state, attribute: :state_id, initial: :active, integration: :custom_attribute) do
      event :ignite do
        transition parked: :idling
      end
    end
    @object = @klass.new
  end

  def teardown
    StateMachines::Integrations.reset
  end

  def test_should_define_a_reader_attribute_for_the_attribute
    assert_respond_to @object, :state_id
  end

  def test_should_define_a_writer_attribute_for_the_attribute
    assert_respond_to @object, :state_id=
  end

  def test_should_define_a_predicate_for_the_attribute
    assert_respond_to @object, :state?
  end

  def test_should_define_a_name_reader_for_the_attribute
    assert_respond_to @object, :state_name
  end

  def test_should_define_a_human_name_reader_for_the_attribute
    assert_respond_to @object, :state_name
  end

  def test_should_define_an_event_reader_for_the_attribute
    assert_respond_to @object, :state_events
  end

  def test_should_define_a_transition_reader_for_the_attribute
    assert_respond_to @object, :state_transitions
  end

  def test_should_define_a_path_reader_for_the_attribute
    assert_respond_to @object, :state_paths
  end

  def test_should_define_an_event_runner_for_the_attribute
    assert_respond_to @object, :fire_state_event
  end

  def test_should_define_a_human_attribute_name_reader
    assert_respond_to @klass, :human_state_name
  end

  def test_should_define_a_human_event_name_reader
    assert_respond_to @klass, :human_state_event_name
  end

  def test_should_define_singular_with_scope
    assert_respond_to @klass, :with_state
  end

  def test_should_define_singular_without_scope
    assert_respond_to @klass, :without_state
  end

  def test_should_define_plural_with_scope
    assert_respond_to @klass, :with_states
  end

  def test_should_define_plural_without_scope
    assert_respond_to @klass, :without_states
  end

  def test_should_define_state_machines_reader
    expected = { state: @machine }

    assert_equal expected, @klass.state_machines
  end
end
