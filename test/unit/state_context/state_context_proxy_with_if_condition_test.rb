require_relative '../../test_helper'

class StateContextProxyWithIfConditionTest < StateMachinesTest
  def setup
    @klass = Class.new(Validateable)
    machine = StateMachines::Machine.new(@klass, initial: :parked)
    state = machine.state :parked

    @state_context = StateMachines::StateContext.new(state)
    @object = @klass.new

    @condition_result = nil
    @options = @state_context.validate(if: lambda { @condition_result })[0]
  end

  def test_should_have_if_option
    refute_nil @options[:if]
  end

  def test_should_be_false_if_state_is_different
    @object.state = nil
    refute @options[:if].call(@object)
  end

  def test_should_be_false_if_original_condition_is_false
    @condition_result = false
    refute @options[:if].call(@object)
  end

  def test_should_be_true_if_state_matches_and_original_condition_is_true
    @condition_result = true
    assert @options[:if].call(@object)
  end

  def test_should_evaluate_symbol_condition
    @klass.class_eval do
      attr_accessor :callback
    end

    options = @state_context.validate(if: :callback)[0]

    object = @klass.new
    object.callback = false
    refute options[:if].call(object)

    object.callback = true
    assert options[:if].call(object)
  end

  def test_should_evaluate_string_condition
    @klass.class_eval do
      attr_accessor :callback
    end

    options = @state_context.validate(if: '@callback')[0]

    object = @klass.new
    object.callback = false
    refute options[:if].call(object)

    object.callback = true
    assert options[:if].call(object)
  end
end
