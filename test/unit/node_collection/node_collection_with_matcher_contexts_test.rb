require_relative '../../test_helper'
require_relative '../../files/node'

class NodeCollectionWithMatcherContextsTest < StateMachinesTest
  def setup
    machine = StateMachines::Machine.new(Class.new)
    @collection = StateMachines::NodeCollection.new(machine)
    @collection << Node.new(:parked)
  end

  def test_should_always_run_all_matcher_context
    contexts_run = []
    @collection.context([StateMachines::AllMatcher.instance]) { contexts_run << :all }
    assert_equal [:all], contexts_run
  end

  def test_should_only_run_blacklist_matcher_if_not_matched
    contexts_run = []
    @collection.context([StateMachines::BlacklistMatcher.new([:parked])]) { contexts_run << :blacklist }
    assert_equal [], contexts_run

    @collection << Node.new(:idling)
    assert_equal [:blacklist], contexts_run
  end
end
