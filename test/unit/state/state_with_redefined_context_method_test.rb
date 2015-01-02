require_relative '../../test_helper'

class StateWithRedefinedContextMethodTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, 'on')

    old_context = nil
    old_speed_method = nil
    @state.context do
      old_context = self

      def speed
        0
      end

      old_speed_method = instance_method(:speed)
    end
    @old_context = old_context
    @old_speed_method = old_speed_method

    current_context = nil
    current_speed_method = nil
    @state.context do
      current_context = self

      def speed
        'green'
      end

      current_speed_method = instance_method(:speed)
    end
    @current_context = current_context
    @current_speed_method = current_speed_method
  end

  def test_should_track_latest_defined_method
    assert_equal @current_speed_method, @state.context_methods[:"__state_on_speed_#{@current_context.object_id}__"]
  end

  def test_should_have_the_same_context
    assert_equal @current_context, @old_context
  end
end
