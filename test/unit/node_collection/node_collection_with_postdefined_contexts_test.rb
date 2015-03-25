require_relative '../../test_helper'
require_relative '../../files/node'

class NodeCollectionWithPostdefinedContextsTest < StateMachinesTest
  def setup
    machine = StateMachines::Machine.new(Class.new)
    @collection = StateMachines::NodeCollection.new(machine)
    @collection << Node.new(:parked)
  end

  def test_should_run_context_if_matched
    contexts_run = []
    @collection.context([:parked]) { contexts_run << :parked }
    assert_equal [:parked], contexts_run
  end

  def test_should_not_run_contexts_if_not_matched
    contexts_run = []
    @collection.context([:idling]) { contexts_run << :idling }
    assert_equal [], contexts_run
  end
end
