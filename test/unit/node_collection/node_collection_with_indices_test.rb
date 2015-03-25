require_relative '../../test_helper'
require_relative '../../files/node'

class NodeCollectionWithIndicesTest < StateMachinesTest
  def setup
    machine = StateMachines::Machine.new(Class.new)
    @collection = StateMachines::NodeCollection.new(machine, index: [:name, :value])

    @object = Node.new(:parked, 1)
    @collection << @object
  end

  def test_should_use_first_index_by_default_on_key_retrieval
    assert_equal [:parked], @collection.keys
  end

  def test_should_allow_customizing_index_for_key_retrieval
    assert_equal [1], @collection.keys(:value)
  end

  def test_should_use_first_index_by_default_on_lookup
    assert_equal @object, @collection[:parked]
    assert_nil @collection[1]
  end

  def test_should_allow_customizing_index_on_lookup
    assert_equal @object, @collection[1, :value]
    assert_nil @collection[:parked, :value]
  end

  def test_should_use_first_index_by_default_on_fetch
    assert_equal @object, @collection.fetch(:parked)
    exception = assert_raises(IndexError) { @collection.fetch(1) }
    assert_equal '1 is an invalid name', exception.message
  end

  def test_should_allow_customizing_index_on_fetch
    assert_equal @object, @collection.fetch(1, :value)
    exception = assert_raises(IndexError) { @collection.fetch(:parked, :value) }
    assert_equal ':parked is an invalid value', exception.message
  end
end
