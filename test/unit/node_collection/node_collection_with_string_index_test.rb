require_relative '../../test_helper'
require_relative '../../files/node'

class NodeCollectionWithStringIndexTest < StateMachinesTest
  def setup
    machine = StateMachines::Machine.new(Class.new)
    @collection = StateMachines::NodeCollection.new(machine, index: [:name, :value])

    @parked = Node.new(:parked, 1)
    @collection << @parked
  end

  def test_should_index_by_name
    assert_equal @parked, @collection[:parked]
  end

  def test_should_index_by_string_name
    assert_equal @parked, @collection['parked']
  end
end
