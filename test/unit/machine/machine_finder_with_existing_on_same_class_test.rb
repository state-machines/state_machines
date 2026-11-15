# frozen_string_literal: true

require 'test_helper'

class MachineFinderWithExistingOnSameClassTest < StateMachinesTest
  def setup
    @klass = Class.new
    @existing_machine = StateMachines::Machine.new(@klass)
    @machine = StateMachines::Machine.find_or_create(@klass)
  end

  def test_should_accept_a_block
    called = false
    StateMachines::Machine.find_or_create(@klass) do
      called = respond_to?(:event)
    end

    assert called
  end

  def test_should_not_create_a_new_machine
    assert_same @machine, @existing_machine
  end

  def test_should_apply_initial_state_when_reopened
    @existing_machine.state :parked, :idling
    StateMachines::Machine.find_or_create(@klass, initial: :idling)

    assert_equal :idling, @existing_machine.initial_state(@klass.new).name
  end

  def test_should_refuse_options_that_only_apply_on_creation
    error = assert_raises(ArgumentError) { StateMachines::Machine.find_or_create(@klass, attribute: :status) }
    assert_match(/Cannot change :attribute of existing state machine :state/, error.message)
    assert_equal :state, @existing_machine.attribute
  end
end
