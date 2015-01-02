require_relative '../../test_helper'

class StateWithSymbolicValueTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, :parked, value: :parked)
  end

  def test_should_use_custom_value
    assert_equal :parked, @state.value
  end

  def test_should_not_include_value_in_description
    assert_equal 'parked', @state.description
  end

  def test_should_allow_human_name_in_description
    @state.human_name = 'Parked'
    assert_equal 'Parked', @state.description(human_name: true)
  end

  def test_should_match_symbolic_value
    assert @state.matches?(:parked)
    refute @state.matches?('parked')
  end

  def test_should_define_predicate
    object = @klass.new
    assert object.respond_to?(:parked?)
  end
end
