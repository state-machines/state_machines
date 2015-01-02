require_relative '../../test_helper'

class TransitionWithActionTest < StateMachinesTest
  def setup
    @klass = Class.new do
      def save
      end
    end

    @machine = StateMachines::Machine.new(@klass, action: :save)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'

    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end

  def test_should_have_an_action
    assert_equal :save, @transition.action
  end

  def test_should_not_have_a_result
    assert_nil @transition.result
  end
end
