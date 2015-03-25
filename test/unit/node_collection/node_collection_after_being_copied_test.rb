require_relative '../../test_helper'
require_relative '../../files/node'

class NodeCollectionAfterBeingCopiedTest < StateMachinesTest
  def setup
    machine = StateMachines::Machine.new(Class.new)
    @collection = StateMachines::NodeCollection.new(machine)
    @collection << @parked = Node.new(:parked)

    @contexts_run = contexts_run = []
    @collection.context([:parked]) { contexts_run << :parked }
    @contexts_run.clear

    @copied_collection = @collection.dup
    @copied_collection << @idling = Node.new(:idling)
    @copied_collection.context([:first_gear]) { contexts_run << :first_gear }
  end

  def test_should_not_modify_the_original_list
    assert_equal 1, @collection.length
    assert_equal 2, @copied_collection.length
  end

  def test_should_not_modify_the_indices
    assert_nil @collection[:idling]
    assert_equal @idling, @copied_collection[:idling]
  end

  def test_should_copy_each_node
    refute_same @parked, @copied_collection[:parked]
  end

  def test_should_not_run_contexts
    assert_equal [], @contexts_run
  end

  def test_should_not_modify_contexts
    @collection << Node.new(:first_gear)
    assert_equal [], @contexts_run
  end

  def test_should_copy_contexts
    @copied_collection << Node.new(:parked)
    refute @contexts_run.empty?
  end
end
