# frozen_string_literal: true

require 'test_helper'
require 'files/node'

class NodeCollectionWithStringKeysTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @collection = StateMachines::NodeCollection.new(@machine, index: %i[name value], string_keys: :name)

    @parked = Node.new(:parked, 1)
    @collection << @parked
  end

  def test_should_find_a_string_keyed_index_by_string
    assert_same @parked, @collection['parked']
  end

  def test_should_find_an_exact_index_by_its_key
    assert_same @parked, @collection[1, :value]
  end

  def test_should_not_find_an_exact_index_by_string
    assert_nil @collection['1', :value]
    assert_nil @collection[:'1', :value]
  end

  def test_should_keep_it_exact_after_update
    @parked.value = 2
    @collection.update(@parked)

    assert_same @parked, @collection[2, :value]
    assert_nil @collection['2', :value]
  end

  def test_should_keep_it_exact_after_being_copied
    copy = @collection.dup

    assert_equal 1, copy[1, :value].value
    assert_nil copy['1', :value]
  end

  def test_should_default_to_every_index
    collection = StateMachines::NodeCollection.new(@machine, index: %i[name value])
    collection << Node.new(:parked, 1)

    assert_equal 1, collection['1', :value].value
  end

  def test_should_raise_for_a_string_key_index_that_is_not_an_index
    error = assert_raises(ArgumentError) { StateMachines::NodeCollection.new(@machine, index: :name, string_keys: :value) }
    assert_equal 'Invalid string_keys: [:value] not in the indices', error.message
  end
end
