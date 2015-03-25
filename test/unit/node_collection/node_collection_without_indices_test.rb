require_relative '../../test_helper'

class NodeCollectionWithoutIndicesTest < StateMachinesTest
  def setup
    machine = StateMachines::Machine.new(Class.new)
    @collection = StateMachines::NodeCollection.new(machine, index: {})
  end

  def test_should_allow_adding_node
    @collection << Object.new
    assert_equal 1, @collection.length
  end

  def test_should_not_allow_keys_retrieval
    exception = assert_raises(ArgumentError) { @collection.keys }
    assert_equal 'No indices configured', exception.message
  end

  def test_should_not_allow_lookup
    @collection << Object.new
    exception = assert_raises(ArgumentError) { @collection[0] }
    assert_equal 'No indices configured', exception.message
  end

  def test_should_not_allow_fetching
    @collection << Object.new
    exception = assert_raises(ArgumentError) { @collection.fetch(0) }
    assert_equal 'No indices configured', exception.message
  end
end
