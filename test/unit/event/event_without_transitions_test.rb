require_relative '../../test_helper'

class EventWithoutTransitionsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
    @object = @klass.new
  end

  def test_should_not_be_able_to_fire
    refute @event.can_fire?(@object)
  end

  def test_should_not_have_a_transition
    assert_nil @event.transition_for(@object)
  end

  def test_should_not_fire
    refute @event.fire(@object)
  end

  def test_should_not_change_the_current_state
    @event.fire(@object)
    assert_nil @object.state
  end
end

