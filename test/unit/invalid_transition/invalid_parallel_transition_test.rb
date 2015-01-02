require_relative '../../test_helper'

class InvalidParallelTransitionTest < StateMachinesTest
  def setup
    @object = Object.new
    @events = [:ignite, :disable_alarm]

    @invalid_transition = StateMachines::InvalidParallelTransition.new(@object, @events)
  end

  def test_should_have_an_object
    assert_equal @object, @invalid_transition.object
  end

  def test_should_have_events
    assert_equal @events, @invalid_transition.events
  end
end
