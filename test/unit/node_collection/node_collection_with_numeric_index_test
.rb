require_relative '../../test_helper'
require_relative '../../files/node'

class NodeCollectionWithNumericIndexTest < StateMachinesTest
  def setup
    machine = StateMachines::Machine.new(Class.new)
    @collection = StateMachines::NodeCollection.new(machine, index: [:name, :value])

    @parked = Node.new(10, 1)
    @collection << @parked
  end

  def test_should_index_by_name
    assert_equal @parked, @collection[10]
  end

  def test_should_index_by_string_name
    assert_equal @parked, @collection['10']
  end

  def test_should_index_by_symbol_name
    assert_equal @parked, @collection[:'10']
  end
end
