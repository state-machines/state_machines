require_relative '../../test_helper'

class MachineWithOwnerSubclassTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @subclass = Class.new(@klass)
  end

  def test_should_have_a_different_collection_of_state_machines
    refute_same @klass.state_machines, @subclass.state_machines
  end

  def test_should_have_the_same_attribute_associated_state_machines
    assert_equal @klass.state_machines, @subclass.state_machines
  end
end

