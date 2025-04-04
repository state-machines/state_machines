# frozen_string_literal: true

require 'test_helper'

class NodeCollectionTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @collection = StateMachines::NodeCollection.new(@machine)
  end

  def test_should_raise_exception_on_lookup_if_invalid_index_specified
    exception = assert_raises(ArgumentError) { @collection[:something, :invalid] }
    assert_equal 'Invalid index: :invalid', exception.message
  end

  def test_should_raise_exception_on_fetch_if_invalid_index_specified
    exception = assert_raises(ArgumentError) { @collection.fetch(:something, :invalid) }
    assert_equal 'Invalid index: :invalid', exception.message
  end
end
