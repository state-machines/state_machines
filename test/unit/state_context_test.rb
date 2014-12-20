require 'test_helper'

class Validateable
  class << self
    def validate(*args, &block)
      args << block if block_given?
      args
    end
  end
end

class StateContextTest < MiniTest::Test
  def setup
    @klass = Class.new(Validateable)
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @state = @machine.state :parked

    @state_context = StateMachines::StateContext.new(@state)
  end

  def test_should_have_a_machine
    assert_equal @machine, @state_context.machine
  end

  def test_should_have_a_state
    assert_equal @state, @state_context.state
  end
end

class StateContextTransitionTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @state = @machine.state :parked

    @state_context = StateMachines::StateContext.new(@state)
  end

  def test_should_not_allow_except_to
    exception = assert_raises(ArgumentError) { @state_context.transition(except_to: :idling) }
    assert_equal 'Unknown key: :except_to. Valid keys are: :from, :to, :on, :if, :unless', exception.message
  end

  def test_should_not_allow_except_from
    exception = assert_raises(ArgumentError) { @state_context.transition(except_from: :idling) }
    assert_equal 'Unknown key: :except_from. Valid keys are: :from, :to, :on, :if, :unless', exception.message
  end

  def test_should_not_allow_implicit_transitions
    exception = assert_raises(ArgumentError) { @state_context.transition(parked: :idling) }
    assert_equal 'Unknown key: :parked. Valid keys are: :from, :to, :on, :if, :unless', exception.message
  end

  def test_should_not_allow_except_on
    exception = assert_raises(ArgumentError) { @state_context.transition(except_on: :park) }
    assert_equal 'Unknown key: :except_on. Valid keys are: :from, :to, :on, :if, :unless', exception.message
  end

  def test_should_require_on_event
    exception = assert_raises(ArgumentError) { @state_context.transition(to: :idling) }
    assert_equal 'Must specify :on event', exception.message
  end

  def test_should_not_allow_missing_from_and_to
    exception = assert_raises(ArgumentError) { @state_context.transition(on: :ignite) }
    assert_equal 'Must specify either :to or :from state', exception.message
  end

  def test_should_not_allow_from_and_to
    exception = assert_raises(ArgumentError) { @state_context.transition(on: :ignite, from: :parked, to: :idling) }
    assert_equal 'Must specify either :to or :from state', exception.message
  end

  def test_should_allow_to_state_if_missing_from_state
    @state_context.transition(on: :park, from: :parked)
  end

  def test_should_allow_from_state_if_missing_to_state
    @state_context.transition(on: :ignite, to: :idling)
  end

  def test_should_automatically_set_to_option_with_from_state
    branch = @state_context.transition(from: :idling, on: :park)
    assert_instance_of StateMachines::Branch, branch

    state_requirements = branch.state_requirements
    assert_equal 1, state_requirements.length

    from_requirement = state_requirements[0][:to]
    assert_instance_of StateMachines::WhitelistMatcher, from_requirement
    assert_equal [:parked], from_requirement.values
  end

  def test_should_automatically_set_from_option_with_to_state
    branch = @state_context.transition(to: :idling, on: :ignite)
    assert_instance_of StateMachines::Branch, branch

    state_requirements = branch.state_requirements
    assert_equal 1, state_requirements.length

    from_requirement = state_requirements[0][:from]
    assert_instance_of StateMachines::WhitelistMatcher, from_requirement
    assert_equal [:parked], from_requirement.values
  end

  def test_should_allow_if_condition
    @state_context.transition(to: :idling, on: :park, if: :seatbelt_on?)
  end

  def test_should_allow_unless_condition
    @state_context.transition(to: :idling, on: :park, unless: :seatbelt_off?)
  end

  def test_should_include_all_transition_states_in_machine_states
    @state_context.transition(to: :idling, on: :ignite)

    assert_equal [:parked, :idling], @machine.states.map { |state| state.name }
  end

  def test_should_include_all_transition_events_in_machine_events
    @state_context.transition(to: :idling, on: :ignite)

    assert_equal [:ignite], @machine.events.map { |event| event.name }
  end

  def test_should_allow_multiple_events
    @state_context.transition(to: :idling, on: [:ignite, :shift_up])

    assert_equal [:ignite, :shift_up], @machine.events.map { |event| event.name }
  end
end

class StateContextWithMatchingTransitionTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @state = @machine.state :parked

    @state_context = StateMachines::StateContext.new(@state)
    @state_context.transition(to: :idling, on: :ignite)

    @event = @machine.event(:ignite)
    @object = @klass.new
  end

  def test_should_be_able_to_fire
    assert @event.can_fire?(@object)
  end

  def test_should_have_a_transition
    transition = @event.transition_for(@object)
    refute_nil transition
    assert_equal 'parked', transition.from
    assert_equal 'idling', transition.to
    assert_equal :ignite, transition.event
  end
end

class StateContextProxyTest < MiniTest::Test
  def setup
    @klass = Class.new(Validateable)
    machine = StateMachines::Machine.new(@klass, initial: :parked)
    state = machine.state :parked

    @state_context = StateMachines::StateContext.new(state)
  end

  def test_should_call_class_with_same_arguments
    options = {}
    validation = @state_context.validate(:name, options)

    assert_equal [:name, options], validation
  end

  def test_should_pass_block_through_to_class
    options = {}
    proxy_block = lambda {}
    validation = @state_context.validate(:name, options, &proxy_block)

    assert_equal [:name, options, proxy_block], validation
  end
end

class StateContextProxyWithoutConditionsTest < MiniTest::Test
  def setup
    @klass = Class.new(Validateable)
    machine = StateMachines::Machine.new(@klass, initial: :parked)
    state = machine.state :parked

    @state_context = StateMachines::StateContext.new(state)
    @object = @klass.new

    @options = @state_context.validate[0]
  end

  def test_should_have_options_configuration
    assert_instance_of Hash, @options
  end

  def test_should_have_if_option
    refute_nil @options[:if]
  end

  def test_should_be_false_if_state_is_different
    @object.state = nil
    assert !@options[:if].call(@object)
  end

  def test_should_be_true_if_state_matches
    assert @options[:if].call(@object)
  end
end

class StateContextProxyWithIfConditionTest < MiniTest::Test
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
    assert !@options[:if].call(@object)
  end

  def test_should_be_false_if_original_condition_is_false
    @condition_result = false
    assert !@options[:if].call(@object)
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
    assert !options[:if].call(object)

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
    assert !options[:if].call(object)

    object.callback = true
    assert options[:if].call(object)
  end
end

class StateContextProxyWithMultipleIfConditionsTest < MiniTest::Test
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
    assert !@options[:if].call(@object)

    @first_condition_result = false
    @second_condition_result = true
    assert !@options[:if].call(@object)
  end
end

class StateContextProxyWithUnlessConditionTest < MiniTest::Test
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
    assert !@options[:if].call(@object)
  end

  def test_should_be_false_if_original_condition_is_true
    @condition_result = true
    assert !@options[:if].call(@object)
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
    assert !options[:if].call(object)

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
    assert !options[:if].call(object)

    object.callback = false
    assert options[:if].call(object)
  end
end

class StateContextProxyWithMultipleUnlessConditionsTest < MiniTest::Test
  def setup
    @klass = Class.new(Validateable)
    machine = StateMachines::Machine.new(@klass, initial: :parked)
    state = machine.state :parked

    @state_context = StateMachines::StateContext.new(state)
    @object = @klass.new

    @first_condition_result = nil
    @second_condition_result = nil
    @options = @state_context.validate(unless: [lambda { @first_condition_result }, lambda { @second_condition_result }])[0]
  end

  def test_should_be_true_if_all_conditions_are_false
    @first_condition_result = false
    @second_condition_result = false
    assert @options[:if].call(@object)
  end

  def test_should_be_false_if_any_condition_is_true
    @first_condition_result = true
    @second_condition_result = false
    assert !@options[:if].call(@object)

    @first_condition_result = false
    @second_condition_result = true
    assert !@options[:if].call(@object)
  end
end

class StateContextProxyWithIfAndUnlessConditionsTest < MiniTest::Test
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
    assert !@options[:if].call(@object)

    @if_condition_result = false
    @unless_condition_result = true
    assert !@options[:if].call(@object)
  end

  def test_should_be_false_if_unless_condition_is_true
    @if_condition_result = false
    @unless_condition_result = true
    assert !@options[:if].call(@object)

    @if_condition_result = true
    @unless_condition_result = true
    assert !@options[:if].call(@object)
  end

  def test_should_be_true_if_if_condition_is_true_and_unless_condition_is_false
    @if_condition_result = true
    @unless_condition_result = false
    assert @options[:if].call(@object)
  end
end
