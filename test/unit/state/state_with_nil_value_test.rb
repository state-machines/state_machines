require_relative '../../test_helper'

class StateWithNilValueTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, :parked, value: nil)
  end

  def test_should_have_a_name
    assert_equal :parked, @state.name
  end

  def test_should_have_a_nil_value
    assert_nil @state.value
  end

  def test_should_match_nil_values
    assert @state.matches?(nil)
  end

  def test_should_have_a_description
    assert_equal 'parked (nil)', @state.description
  end

  def test_should_have_a_description_with_human_name
    @state.human_name = 'Parked'
    assert_equal 'Parked (nil)', @state.description(human_name: true)
  end

  def test_should_define_predicate
    object = @klass.new
    assert object.respond_to?(:parked?)
  end
end
