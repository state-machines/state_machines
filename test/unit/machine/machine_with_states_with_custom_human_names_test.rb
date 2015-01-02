require_relative '../../test_helper'

class MachineWithStatesWithCustomHumanNamesTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @state = @machine.state :parked, human_name: 'stopped'
  end

  def test_should_use_custom_human_name
    assert_equal 'stopped', @state.human_name
  end

  def test_should_allow_human_state_name_lookup
    assert_equal 'stopped', @klass.human_state_name(:parked)
  end
end

