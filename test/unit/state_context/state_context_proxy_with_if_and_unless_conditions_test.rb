require_relative '../../test_helper'

class StateContextProxyWithIfAndUnlessConditionsTest < StateMachinesTest
  def setup
    @klass = Class.new(Validateable)
    machine = StateMachines::Machine.new(@klass, initial: :parked)
    state = machine.state :parked

    @state_context = StateMachines::StateContext.new(state)
    @object = @klass.new

    @if_condition_result = nil
    @unless_condition_result = nil
    @options = @state_context.validate(if: lambda { @if_condition_result }, unless: lambda { @unless_condition_result })[0]
  end

  def test_should_be_false_if_if_condition_is_false
    @if_condition_result = false
    @unless_condition_result = false
    refute @options[:if].call(@object)

    @if_condition_result = false
    @unless_condition_result = true
    refute @options[:if].call(@object)
  end

  def test_should_be_false_if_unless_condition_is_true
    @if_condition_result = false
    @unless_condition_result = true
    refute @options[:if].call(@object)

    @if_condition_result = true
    @unless_condition_result = true
    refute @options[:if].call(@object)
  end

  def test_should_be_true_if_if_condition_is_true_and_unless_condition_is_false
    @if_condition_result = true
    @unless_condition_result = false
    assert @options[:if].call(@object)
  end
end
