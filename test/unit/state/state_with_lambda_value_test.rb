require_relative '../../test_helper'

class StateWithLambdaValueTest < StateMachinesTest
  def setup
    @klass = Class.new
    @args = nil
    @machine = StateMachines::Machine.new(@klass)
    @value = ->(*args) { @args = args; :parked }
    @machine.states << @state = StateMachines::State.new(@machine, :parked, value: @value)
  end

  def test_should_use_evaluated_value_by_default
    assert_equal :parked, @state.value
  end

  def test_should_allow_access_to_original_value
    assert_equal @value, @state.value(false)
  end

  def test_should_include_masked_value_in_description
    assert_equal 'parked (*)', @state.description
  end

  def test_should_not_pass_in_any_arguments
    @state.value
    assert_equal [], @args
  end

  def test_should_define_predicate
    object = @klass.new
    assert object.respond_to?(:parked?)
  end

  def test_should_match_evaluated_value
    assert @state.matches?(:parked)
  end
end
