require_relative '../../test_helper'

class StateContextProxyWithUnlessConditionTest < StateMachinesTest
  def setup
    @klass = Class.new(Validateable)
    machine = StateMachines::Machine.new(@klass, initial: :parked)
    state = machine.state :parked

    @state_context = StateMachines::StateContext.new(state)
    @object = @klass.new

    @condition_result = nil
    @options = @state_context.validate(unless: lambda { @condition_result })[0]
  end

  def test_should_have_if_option
    refute_nil @options[:if]
  end

  def test_should_be_false_if_state_is_different
    @object.state = nil
    refute @options[:if].call(@object)
  end

  def test_should_be_false_if_original_condition_is_true
    @condition_result = true
    refute @options[:if].call(@object)
  end

  def test_should_be_true_if_state_matches_and_original_condition_is_false
    @condition_result = false
    assert @options[:if].call(@object)
  end

  def test_should_evaluate_symbol_condition
    @klass.class_eval do
      attr_accessor :callback
    end

    options = @state_context.validate(unless: :callback)[0]

    object = @klass.new
    object.callback = true
    refute options[:if].call(object)

    object.callback = false
    assert options[:if].call(object)
  end

  def test_should_evaluate_string_condition
    @klass.class_eval do
      attr_accessor :callback
    end

    options = @state_context.validate(unless: '@callback')[0]

    object = @klass.new
    object.callback = true
    refute options[:if].call(object)

    object.callback = false
    assert options[:if].call(object)
  end
end
