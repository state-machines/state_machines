# frozen_string_literal: true

require 'test_helper'
require 'files/node'

# nil.to_s is '', so a string-normalized lookup used to make a nil key and a
# :"" key the same key.
class NodeCollectionWithNilAndBlankKeysTest < StateMachinesTest
  def setup
    machine = StateMachines::Machine.new(Class.new)
    @collection = StateMachines::NodeCollection.new(machine, index: %i[name value])

    @blank = Node.new(:'', '')
    @nil = Node.new(nil, nil)
    @collection << @blank << @nil
  end

  def test_should_find_nil_by_nil
    assert_same @nil, @collection[nil]
    assert_same @nil, @collection[nil, :value]
  end

  def test_should_find_blank_by_symbol_and_string
    assert_same @blank, @collection[:'']
    assert_same @blank, @collection['']
  end

  def test_should_find_blank_value_by_string_and_symbol
    assert_same @blank, @collection['', :value]
    assert_same @blank, @collection[:'', :value]
  end

  def test_should_fetch_both
    assert_same @nil, @collection.fetch(nil)
    assert_same @blank, @collection.fetch(:'')
  end

  def test_should_keep_both_keys
    assert_equal [:'', nil], @collection.keys
    assert_equal ['', nil], @collection.keys(:value)
  end

  def test_should_not_find_nil_by_blank_when_only_nil_is_indexed
    collection = StateMachines::NodeCollection.new(StateMachines::Machine.new(Class.new))
    collection << Node.new(nil, nil)

    assert_nil collection[:'']
    assert_nil collection['']
    assert_raises(IndexError) { collection.fetch(:'') }
  end

  def test_should_not_find_blank_by_nil_when_only_blank_is_indexed
    collection = StateMachines::NodeCollection.new(StateMachines::Machine.new(Class.new))
    collection << Node.new(:'', '')

    assert_nil collection[nil]
    assert_raises(IndexError) { collection.fetch(nil) }
  end

  def test_should_not_treat_nil_as_the_string_nil
    collection = StateMachines::NodeCollection.new(StateMachines::Machine.new(Class.new))
    collection << named_nil = Node.new(:nil, 'nil')
    collection << Node.new(nil, nil)

    assert_same named_nil, collection['nil']
    refute_same named_nil, collection[nil]
  end

  def test_should_keep_blank_when_nil_node_is_renamed
    @nil.name = :parked
    @collection.update(@nil)

    assert_nil @collection[nil]
    assert_same @nil, @collection[:parked]
    assert_same @blank, @collection['']
  end

  def test_should_keep_both_after_being_copied
    copy = @collection.dup

    assert_equal [nil, nil], [copy[nil].name, copy[nil, :value].value]
    assert_equal [:'', ''], [copy[''].name, copy[:'', :value].value]
  end
end
