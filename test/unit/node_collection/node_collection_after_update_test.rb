require_relative '../../test_helper'
require_relative '../../files/node'

class NodeCollectionAfterUpdateTest < StateMachinesTest
  def setup
    machine = StateMachines::Machine.new(Class.new)
    @collection = StateMachines::NodeCollection.new(machine, index: [:name, :value])

    @parked = Node.new(:parked, 1)
    @idling = Node.new(:idling, 2)

    @collection << @parked << @idling

    @parked.name = :parking
    @parked.value = 0
    @collection.update(@parked)
  end

  def test_should_not_change_the_index
    assert_equal @parked, @collection.at(0)
  end

  def test_should_not_duplicate_in_the_collection
    assert_equal 2, @collection.length
  end

  def test_should_add_each_indexed_key
    assert_equal @parked, @collection[:parking]
    assert_equal @parked, @collection[0, :value]
  end

  def test_should_remove_each_old_indexed_key
    assert_nil @collection[:parked]
    assert_nil @collection[1, :value]
  end
end
