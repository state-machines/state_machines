require_relative '../../test_helper'

class StateWithNameTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, :parked)
  end

  def test_should_have_a_name
    assert_equal :parked, @state.name
  end

  def test_should_have_a_qualified_name
    assert_equal :parked, @state.name
  end

  def test_should_have_a_human_name
    assert_equal 'parked', @state.human_name
  end

  def test_should_use_stringify_the_name_as_the_value
    assert_equal 'parked', @state.value
  end

  def test_should_match_stringified_name
    assert @state.matches?('parked')
    refute @state.matches?('idling')
  end

  def test_should_not_include_value_in_description
    assert_equal 'parked', @state.description
  end

  def test_should_allow_using_human_name_in_description
    @state.human_name = 'Parked'
    assert_equal 'Parked', @state.description(human_name: true)
  end

  def test_should_define_predicate
    assert @klass.new.respond_to?(:parked?)
  end
end
