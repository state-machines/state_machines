require_relative '../../test_helper'

class StateWithHumanNameTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, :parked, human_name: 'stopped')
  end

  def test_should_use_custom_human_name
    assert_equal 'stopped', @state.human_name
  end
end
