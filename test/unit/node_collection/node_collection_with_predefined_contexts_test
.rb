require_relative '../../test_helper'
require_relative '../../files/node'

class NodeCollectionWithPredefinedContextsTest < StateMachinesTest
  def setup
    machine = StateMachines::Machine.new(Class.new)
    @collection = StateMachines::NodeCollection.new(machine)

    @contexts_run = contexts_run = []
    @collection.context([:parked]) { contexts_run << :parked }
    @collection.context([:parked]) { contexts_run << :second_parked }
  end

  def test_should_run_contexts_in_the_order_defined
    @collection << Node.new(:parked)
    assert_equal [:parked, :second_parked], @contexts_run
  end

  def test_should_not_run_contexts_if_not_matched
    @collection << Node.new(:idling)
    assert_equal [], @contexts_run
  end
end
