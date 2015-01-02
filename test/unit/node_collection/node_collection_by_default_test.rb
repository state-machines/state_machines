require_relative '../../test_helper'
require_relative '../../files/node'

class NodeCollectionByDefaultTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @collection = StateMachines::NodeCollection.new(@machine)
  end

  def test_should_not_have_any_nodes
    assert_equal 0, @collection.length
  end

  def test_should_have_a_machine
    assert_equal @machine, @collection.machine
  end

  def test_should_index_by_name
    @collection << object = Node.new(:parked)
    assert_equal object, @collection[:parked]
  end
end
