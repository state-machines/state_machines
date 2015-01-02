require_relative '../../test_helper'

class StateWithDynamicHumanNameTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, :parked, human_name: lambda { |_state, object| ['stopped', object] })
  end

  def test_should_use_custom_human_name
    human_name, klass = @state.human_name
    assert_equal 'stopped', human_name
    assert_equal @klass, klass
  end

  def test_should_allow_custom_class_to_be_passed_through
    human_name, klass = @state.human_name(1)
    assert_equal 'stopped', human_name
    assert_equal 1, klass
  end

  def test_should_not_cache_value
    refute_same @state.human_name, @state.human_name
  end
end
