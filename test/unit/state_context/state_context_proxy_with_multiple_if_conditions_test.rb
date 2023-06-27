require 'test_helper'

class StateContextProxyWithMultipleIfConditionsTest < StateMachinesTest
  def setup
    @klass = Class.new(Validateable)
    machine = StateMachines::Machine.new(@klass, initial: :parked)
    state = machine.state :parked

    @state_context = StateMachines::StateContext.new(state)
    @object = @klass.new

    @first_condition_result = nil
    @second_condition_result = nil
    @options = @state_context.validate(if: [lambda { @first_condition_result }, lambda { @second_condition_result }])[0]
  end

  def test_should_be_true_if_all_conditions_are_true
    @first_condition_result = true
    @second_condition_result = true
    assert @options[:if].call(@object)
  end

  def test_should_be_false_if_any_condition_is_false
    @first_condition_result = true
    @second_condition_result = false
    refute @options[:if].call(@object)

    @first_condition_result = false
    @second_condition_result = true
    refute @options[:if].call(@object)
  end
end
