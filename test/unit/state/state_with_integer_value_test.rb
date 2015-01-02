require_relative '../../test_helper'

class StateWithIntegerValueTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, :parked, value: 1)
  end

  def test_should_use_custom_value
    assert_equal 1, @state.value
  end

  def test_should_include_value_in_description
    assert_equal 'parked (1)', @state.description
  end

  def test_should_allow_human_name_in_description
    @state.human_name = 'Parked'
    assert_equal 'Parked (1)', @state.description(human_name: true)
  end

  def test_should_match_integer_value
    assert @state.matches?(1)
    refute @state.matches?(2)
  end

  def test_should_define_predicate
    object = @klass.new
    assert object.respond_to?(:parked?)
  end
end
