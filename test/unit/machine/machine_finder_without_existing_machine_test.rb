require_relative '../../test_helper'

class MachineFinderWithoutExistingMachineTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.find_or_create(@klass)
  end

  def test_should_accept_a_block
    called = false
    StateMachines::Machine.find_or_create(Class.new) do
      called = respond_to?(:event)
    end

    assert called
  end

  def test_should_create_a_new_machine
    refute_nil @machine
  end

  def test_should_use_default_state
    assert_equal :state, @machine.attribute
  end
end
