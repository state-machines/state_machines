require_relative '../../test_helper'
require_relative '../../files/node'

class NodeCollectionWithNodesTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @collection = StateMachines::NodeCollection.new(@machine)

    @parked = Node.new(:parked, nil, @machine)
    @idling = Node.new(:idling, nil, @machine)

    @collection << @parked
    @collection << @idling
  end

  def test_should_be_able_to_enumerate
    order = []
    @collection.each { |object| order << object }

    assert_equal [@parked, @idling], order
  end

  def test_should_be_able_to_concatenate_multiple_nodes
    @first_gear = Node.new(:first_gear, nil, @machine)
    @second_gear = Node.new(:second_gear, nil, @machine)
    @collection.concat([@first_gear, @second_gear])

    order = []
    @collection.each { |object| order << object }
    assert_equal [@parked, @idling, @first_gear, @second_gear], order
  end

  def test_should_be_able_to_access_by_index
    assert_equal @parked, @collection.at(0)
    assert_equal @idling, @collection.at(1)
  end

  def test_should_deep_copy_machine_changes
    new_machine = StateMachines::Machine.new(Class.new)
    @collection.machine = new_machine

    assert_equal new_machine, @collection.machine
    assert_equal new_machine, @parked.machine
    assert_equal new_machine, @idling.machine
  end
end
