require_relative '../../test_helper'

class EventTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
    @event.transition parked: :idling
  end

  def test_should_allow_changing_machine
    new_machine = StateMachines::Machine.new(Class.new)
    @event.machine = new_machine
    assert_equal new_machine, @event.machine
  end

  def test_should_allow_changing_human_name
    @event.human_name = 'Stop'
    assert_equal 'Stop', @event.human_name
  end

  def test_should_provide_matcher_helpers_during_initialization
    matchers = []

    @event.instance_eval do
      matchers = [all, any, same]
    end

    assert_equal [StateMachines::AllMatcher.instance, StateMachines::AllMatcher.instance, StateMachines::LoopbackMatcher.instance], matchers
  end

  def test_should_use_pretty_inspect
    assert_match '#<StateMachines::Event name=:ignite transitions=[:parked => :idling]>', @event.inspect
  end
end
