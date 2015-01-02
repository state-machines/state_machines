require_relative '../../test_helper'

class StateWithMatcherTest < StateMachinesTest
  def setup
    @klass = Class.new
    @args = nil
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, :parked, if: lambda { |value| value == 1 })
  end

  def test_should_not_match_actual_value
    refute @state.matches?('parked')
  end

  def test_should_match_evaluated_block
    assert @state.matches?(1)
  end
end
