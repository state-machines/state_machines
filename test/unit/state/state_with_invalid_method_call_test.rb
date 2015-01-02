require_relative '../../test_helper'

class StateWithInvalidMethodCallTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @ancestors = @klass.ancestors
    @machine.states << @state = StateMachines::State.new(@machine, :idling)
    @state.context do
      def speed
        0
      end
    end

    @object = @klass.new
  end

  def test_should_call_method_missing_arg
    assert_equal 1, @state.call(@object, :invalid, method_missing: -> { 1 })
  end
end
