require_relative '../../test_helper'

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
end

