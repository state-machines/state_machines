require_relative '../../test_helper'

class StateByDefaultTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @machine.states << @state = StateMachines::State.new(@machine, :parked)
  end

  def test_should_have_a_machine
    assert_equal @machine, @state.machine
  end

  def test_should_have_a_name
    assert_equal :parked, @state.name
  end

  def test_should_have_a_qualified_name
    assert_equal :parked, @state.qualified_name
  end

  def test_should_have_a_human_name
    assert_equal 'parked', @state.human_name
  end

  def test_should_use_stringify_the_name_as_the_value
    assert_equal 'parked', @state.value
  end

  def test_should_not_be_initial
    refute @state.initial
  end

  def test_should_not_have_a_matcher
    assert_nil @state.matcher
  end

  def test_should_not_have_any_methods
    expected = {}
    assert_equal expected, @state.context_methods
  end
end
