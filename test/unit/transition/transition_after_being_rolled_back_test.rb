require_relative '../../test_helper'

class TransitionAfterBeingRolledBackTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, action: :save)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'

    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    @object.state = 'idling'

    @transition.rollback
  end

  def test_should_update_state_value_to_from_state
    assert_equal 'parked', @object.state
  end

  def test_should_not_change_from_state
    assert_equal 'parked', @transition.from
  end

  def test_should_not_change_to_state
    assert_equal 'idling', @transition.to
  end

  def test_should_still_be_able_to_persist
    @transition.persist
    assert_equal 'idling', @object.state
  end
end
