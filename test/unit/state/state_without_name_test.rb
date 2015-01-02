require_relative '../../test_helper'

class StateWithoutNameTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, nil)
  end

  def test_should_have_a_nil_name
    assert_nil @state.name
  end

  def test_should_have_a_nil_qualified_name
    assert_nil @state.qualified_name
  end

  def test_should_have_an_empty_human_name
    assert_equal 'nil', @state.human_name
  end

  def test_should_have_a_nil_value
    assert_nil @state.value
  end

  def test_should_not_redefine_nil_predicate
    object = @klass.new
    refute object.nil?
    refute object.respond_to?('?')
  end

  def test_should_have_a_description
    assert_equal 'nil', @state.description
  end

  def test_should_have_a_description_using_human_name
    assert_equal 'nil', @state.description(human_name: true)
  end
end
