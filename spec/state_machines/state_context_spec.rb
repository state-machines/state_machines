require 'spec_helper'

class Validateable
  class << self
    def validate(*args, &block)
      args << block if block_given?
      args
    end
  end
end
describe StateMachines::StateContext do
  context '' do
    before(:each) do
      @klass = Class.new(Validateable)
      @machine = StateMachines::Machine.new(@klass, :initial => :parked)
      @state = @machine.state :parked

      @state_context = StateMachines::StateContext.new(@state)
    end

    it 'should_have_a_machine' do
      assert_equal @machine, @state_context.machine
    end

    it 'should_have_a_state' do
      assert_equal @state, @state_context.state
    end
  end

  context 'Transition' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass, :initial => :parked)
      @state = @machine.state :parked

      @state_context = StateMachines::StateContext.new(@state)
    end

    it 'should_not_allow_except_to' do
      assert_raise(ArgumentError) { @state_context.transition(:except_to => :idling) }
      # assert_equal 'Invalid key(s): except_to', exception.message
    end

    it 'should_not_allow_except_from' do
      assert_raise(ArgumentError) { @state_context.transition(:except_from => :idling) }
      #assert_equal 'Invalid key(s): except_from', exception.message
    end

    it 'should_not_allow_implicit_transitions' do
      assert_raise(ArgumentError) { @state_context.transition(:parked => :idling) }
      #assert_equal 'Invalid key(s): parked', exception.message
    end

    it 'should_not_allow_except_on' do
      assert_raise(ArgumentError) { @state_context.transition(:except_on => :park) }
      #assert_equal 'Invalid key(s): except_on', exception.message
    end

    it 'should_require_on_event' do
      assert_raise(ArgumentError) { @state_context.transition(:to => :idling) }
      #assert_equal 'Must specify :on event', exception.message
    end

    it 'should_not_allow_missing_from_and_to' do
      assert_raise(ArgumentError) { @state_context.transition(:on => :ignite) }
      #assert_equal 'Must specify either :to or :from state', exception.message
    end

    it 'should_not_allow_from_and_to' do
      assert_raise(ArgumentError) { @state_context.transition(:on => :ignite, :from => :parked, :to => :idling) }
      #assert_equal 'Must specify either :to or :from state', exception.message
    end

    it 'should_allow_to_state_if_missing_from_state' do
      assert_nothing_raised { @state_context.transition(:on => :park, :from => :parked) }
    end

    it 'should_allow_from_state_if_missing_to_state' do
      assert_nothing_raised { @state_context.transition(:on => :ignite, :to => :idling) }
    end

    it 'should_automatically_set_to_option_with_from_state' do
      branch = @state_context.transition(:from => :idling, :on => :park)
      assert_instance_of StateMachines::Branch, branch

      state_requirements = branch.state_requirements
      assert_equal 1, state_requirements.length

      from_requirement = state_requirements[0][:to]
      assert_instance_of StateMachines::WhitelistMatcher, from_requirement
      assert_equal [:parked], from_requirement.values
    end

    it 'should_automatically_set_from_option_with_to_state' do
      branch = @state_context.transition(:to => :idling, :on => :ignite)
      assert_instance_of StateMachines::Branch, branch

      state_requirements = branch.state_requirements
      assert_equal 1, state_requirements.length

      from_requirement = state_requirements[0][:from]
      assert_instance_of StateMachines::WhitelistMatcher, from_requirement
      assert_equal [:parked], from_requirement.values
    end

    it 'should_allow_if_condition' do
      assert_nothing_raised { @state_context.transition(:to => :idling, :on => :park, :if => :seatbelt_on?) }
    end

    it 'should_allow_unless_condition' do
      assert_nothing_raised { @state_context.transition(:to => :idling, :on => :park, :unless => :seatbelt_off?) }
    end

    it 'should_include_all_transition_states_in_machine_states' do
      @state_context.transition(:to => :idling, :on => :ignite)

      assert_equal [:parked, :idling], @machine.states.map { |state| state.name }
    end

    it 'should_include_all_transition_events_in_machine_events' do
      @state_context.transition(:to => :idling, :on => :ignite)

      assert_equal [:ignite], @machine.events.map { |event| event.name }
    end

    it 'should_allow_multiple_events' do
      @state_context.transition(:to => :idling, :on => [:ignite, :shift_up])

      assert_equal [:ignite, :shift_up], @machine.events.map { |event| event.name }
    end
  end

  context 'WithMatchingTransition' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass, :initial => :parked)
      @state = @machine.state :parked

      @state_context = StateMachines::StateContext.new(@state)
      @state_context.transition(:to => :idling, :on => :ignite)

      @event = @machine.event(:ignite)
      @object = @klass.new
    end

    it 'should_be_able_to_fire' do
      assert @event.can_fire?(@object)
    end

    it 'should_have_a_transition' do
      transition = @event.transition_for(@object)
      assert_not_nil transition
      assert_equal 'parked', transition.from
      assert_equal 'idling', transition.to
      assert_equal :ignite, transition.event
    end
  end

  context 'Proxy' do
    before(:each) do
      @klass = Class.new(Validateable)
      machine = StateMachines::Machine.new(@klass, :initial => :parked)
      state = machine.state :parked

      @state_context = StateMachines::StateContext.new(state)
    end

    it 'should_call_class_with_same_arguments' do
      options = {}
      validation = @state_context.validate(:name, options)

      assert_equal [:name, options], validation
    end

    it 'should_pass_block_through_to_class' do
      options = {}
      proxy_block = lambda {}
      validation = @state_context.validate(:name, options, &proxy_block)

      assert_equal [:name, options, proxy_block], validation
    end
  end

  context 'ProxyWithoutConditions' do
    before(:each) do
      @klass = Class.new(Validateable)
      machine = StateMachines::Machine.new(@klass, :initial => :parked)
      state = machine.state :parked

      @state_context = StateMachines::StateContext.new(state)
      @object = @klass.new

      @options = @state_context.validate[0]
    end

    it 'should_have_options_configuration' do
      assert_instance_of Hash, @options
    end

    it 'should_have_if_option' do
      assert_not_nil @options[:if]
    end

    it 'should_be_false_if_state_is_different' do
      @object.state = nil
      assert !@options[:if].call(@object)
    end

    it 'should_be_true_if_state_matches' do
      assert @options[:if].call(@object)
    end
  end

  context 'ProxyWithIfCondition' do
    before(:each) do
      @klass = Class.new(Validateable)
      machine = StateMachines::Machine.new(@klass, :initial => :parked)
      state = machine.state :parked

      @state_context = StateMachines::StateContext.new(state)
      @object = @klass.new

      @condition_result = nil
      @options = @state_context.validate(:if => lambda { @condition_result })[0]
    end

    it 'should_have_if_option' do
      assert_not_nil @options[:if]
    end

    it 'should_be_false_if_state_is_different' do
      @object.state = nil
      assert !@options[:if].call(@object)
    end

    it 'should_be_false_if_original_condition_is_false' do
      @condition_result = false
      assert !@options[:if].call(@object)
    end

    it 'should_be_true_if_state_matches_and_original_condition_is_true' do
      @condition_result = true
      assert @options[:if].call(@object)
    end

    it 'should_evaluate_symbol_condition' do
      @klass.class_eval do
        attr_accessor :callback
      end

      options = @state_context.validate(:if => :callback)[0]

      object = @klass.new
      object.callback = false
      assert !options[:if].call(object)

      object.callback = true
      assert options[:if].call(object)
    end

    it 'should_evaluate_string_condition' do
      @klass.class_eval do
        attr_accessor :callback
      end

      options = @state_context.validate(:if => '@callback')[0]

      object = @klass.new
      object.callback = false
      assert !options[:if].call(object)

      object.callback = true
      assert options[:if].call(object)
    end
  end

  context 'ProxyWithMultipleIfConditions' do
    before(:each) do
      @klass = Class.new(Validateable)
      machine = StateMachines::Machine.new(@klass, :initial => :parked)
      state = machine.state :parked

      @state_context = StateMachines::StateContext.new(state)
      @object = @klass.new

      @first_condition_result = nil
      @second_condition_result = nil
      @options = @state_context.validate(:if => [lambda { @first_condition_result }, lambda { @second_condition_result }])[0]
    end

    it 'should_be_true_if_all_conditions_are_true' do
      @first_condition_result = true
      @second_condition_result = true
      assert @options[:if].call(@object)
    end

    it 'should_be_false_if_any_condition_is_false' do
      @first_condition_result = true
      @second_condition_result = false
      assert !@options[:if].call(@object)

      @first_condition_result = false
      @second_condition_result = true
      assert !@options[:if].call(@object)
    end
  end

  context 'ProxyWithUnlessCondition' do
    before(:each) do
      @klass = Class.new(Validateable)
      machine = StateMachines::Machine.new(@klass, :initial => :parked)
      state = machine.state :parked

      @state_context = StateMachines::StateContext.new(state)
      @object = @klass.new

      @condition_result = nil
      @options = @state_context.validate(:unless => lambda { @condition_result })[0]
    end

    it 'should_have_if_option' do
      assert_not_nil @options[:if]
    end

    it 'should_be_false_if_state_is_different' do
      @object.state = nil
      assert !@options[:if].call(@object)
    end

    it 'should_be_false_if_original_condition_is_true' do
      @condition_result = true
      assert !@options[:if].call(@object)
    end

    it 'should_be_true_if_state_matches_and_original_condition_is_false' do
      @condition_result = false
      assert @options[:if].call(@object)
    end

    it 'should_evaluate_symbol_condition' do
      @klass.class_eval do
        attr_accessor :callback
      end

      options = @state_context.validate(:unless => :callback)[0]

      object = @klass.new
      object.callback = true
      assert !options[:if].call(object)

      object.callback = false
      assert options[:if].call(object)
    end

    it 'should_evaluate_string_condition' do
      @klass.class_eval do
        attr_accessor :callback
      end

      options = @state_context.validate(:unless => '@callback')[0]

      object = @klass.new
      object.callback = true
      assert !options[:if].call(object)

      object.callback = false
      assert options[:if].call(object)
    end
  end

  context 'ProxyWithMultipleUnlessConditions' do
    before(:each) do
      @klass = Class.new(Validateable)
      machine = StateMachines::Machine.new(@klass, :initial => :parked)
      state = machine.state :parked

      @state_context = StateMachines::StateContext.new(state)
      @object = @klass.new

      @first_condition_result = nil
      @second_condition_result = nil
      @options = @state_context.validate(:unless => [lambda { @first_condition_result }, lambda { @second_condition_result }])[0]
    end

    it 'should_be_true_if_all_conditions_are_false' do
      @first_condition_result = false
      @second_condition_result = false
      assert @options[:if].call(@object)
    end

    it 'should_be_false_if_any_condition_is_true' do
      @first_condition_result = true
      @second_condition_result = false
      assert !@options[:if].call(@object)

      @first_condition_result = false
      @second_condition_result = true
      assert !@options[:if].call(@object)
    end
  end

  context 'ProxyWithIfAndUnlessConditions' do
    before(:each) do
      @klass = Class.new(Validateable)
      machine = StateMachines::Machine.new(@klass, :initial => :parked)
      state = machine.state :parked

      @state_context = StateMachines::StateContext.new(state)
      @object = @klass.new

      @if_condition_result = nil
      @unless_condition_result = nil
      @options = @state_context.validate(:if => lambda { @if_condition_result }, :unless => lambda { @unless_condition_result })[0]
    end

    it 'should_be_false_if_if_condition_is_false' do
      @if_condition_result = false
      @unless_condition_result = false
      assert !@options[:if].call(@object)

      @if_condition_result = false
      @unless_condition_result = true
      assert !@options[:if].call(@object)
    end

    it 'should_be_false_if_unless_condition_is_true' do
      @if_condition_result = false
      @unless_condition_result = true
      assert !@options[:if].call(@object)

      @if_condition_result = true
      @unless_condition_result = true
      assert !@options[:if].call(@object)
    end

    it 'should_be_true_if_if_condition_is_true_and_unless_condition_is_false' do
      @if_condition_result = true
      @unless_condition_result = false
      assert @options[:if].call(@object)
    end
  end
end
