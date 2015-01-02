require_relative '../../test_helper'

class TransitionWithPerformArgumentsTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_reader :saved

      def save
        @saved = true
      end
    end

    @machine = StateMachines::Machine.new(@klass, action: :save)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end

  def test_should_have_arguments
    @transition.perform(1, 2)

    assert_equal [1, 2], @transition.args
    assert @object.saved
  end

  def test_should_not_include_run_action_in_arguments
    @transition.perform(1, 2, false)

    assert_equal [1, 2], @transition.args
    refute @object.saved
  end
end
