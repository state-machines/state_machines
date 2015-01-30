require_relative '../../test_helper'

class MachineFinderWithExistingMachineOnSuperclassTest < StateMachinesTest
  module Custom
    include StateMachines::Integrations::Base

    def self.matches?(_klass)
      false
    end
  end

  def setup
    StateMachines::Integrations.register(MachineFinderWithExistingMachineOnSuperclassTest::Custom)

    @base_class = Class.new
    @base_machine = StateMachines::Machine.new(@base_class, :status, action: :save, integration: :custom)
    @base_machine.event(:ignite) {}
    @base_machine.before_transition(-> {})
    @base_machine.after_transition(-> {})
    @base_machine.around_transition(-> {})

    @klass = Class.new(@base_class)
    @machine = StateMachines::Machine.find_or_create(@klass, :status) {}
  end

  def test_should_accept_a_block
    called = false
    StateMachines::Machine.find_or_create(Class.new(@base_class)) do
      called = respond_to?(:event)
    end

    assert called
  end

  def test_should_not_create_a_new_machine_if_no_block_or_options
    machine = StateMachines::Machine.find_or_create(Class.new(@base_class), :status)

    assert_same machine, @base_machine
  end

  def test_should_create_a_new_machine_if_given_options
    machine = StateMachines::Machine.find_or_create(@klass, :status, initial: :parked)

    refute_nil machine
    refute_same machine, @base_machine
  end

  def test_should_create_a_new_machine_if_given_block
    refute_nil @machine
    refute_same @machine, @base_machine
  end

  def test_should_copy_the_base_attribute
    assert_equal :status, @machine.attribute
  end

  def test_should_copy_the_base_configuration
    assert_equal :save, @machine.action
  end

  def test_should_copy_events
    # Can't assert equal arrays since their machines change
    assert_equal 1, @machine.events.length
  end

  def test_should_copy_before_callbacks
    assert_equal @base_machine.callbacks[:before], @machine.callbacks[:before]
  end

  def test_should_copy_after_transitions
    assert_equal @base_machine.callbacks[:after], @machine.callbacks[:after]
  end

  def test_should_use_the_same_integration
    class_ancestors = class << @machine
      ancestors
    end

    assert(class_ancestors.include?(MachineFinderWithExistingMachineOnSuperclassTest::Custom))
  end

  def teardown
    StateMachines::Integrations.reset
  end
end
