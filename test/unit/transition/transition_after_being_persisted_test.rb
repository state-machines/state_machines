require_relative '../../test_helper'

class TransitionAfterBeingPersistedTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, action: :save)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'

    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    @transition.persist
  end

  def test_should_update_state_value
    assert_equal 'idling', @object.state
  end

  def test_should_not_change_from_state
    assert_equal 'parked', @transition.from
  end

  def test_should_not_change_to_state
    assert_equal 'idling', @transition.to
  end

  def test_should_not_be_able_to_persist_twice
    @object.state = 'parked'
    @transition.persist
    assert_equal 'parked', @object.state
  end

  def test_should_be_able_to_persist_again_after_resetting
    @object.state = 'parked'
    @transition.reset
    @transition.persist
    assert_equal 'idling', @object.state
  end

  def test_should_revert_to_from_state_on_rollback
    @transition.rollback
    assert_equal 'parked', @object.state
  end
end
