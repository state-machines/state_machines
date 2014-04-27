require 'spec_helper'
describe StateMachines::TransitionCollection do
  context '' do
    it 'should_raise_exception_if_invalid_option_specified' do
      assert_raise(ArgumentError) { StateMachines::TransitionCollection.new([], :invalid => true) }
      #assert_equal 'Invalid key(s): invalid', exception.message
    end

    it 'should_raise_exception_if_multiple_transitions_for_same_attribute_specified' do
      @klass = Class.new

      @machine = StateMachines::Machine.new(@klass, :initial => :parked)
      @machine.state :parked, :idling
      @machine.event :ignite

      @object = @klass.new

      assert_raise(ArgumentError) do
        StateMachines::TransitionCollection.new([
                                                    StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
                                                    StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                ])
      end
      #assert_equal 'Cannot perform multiple transitions in parallel for the same state machine attribute', exception.message
    end
  end

  context 'ByDefault' do
    before(:each) do
      @transitions = StateMachines::TransitionCollection.new
    end

    it 'should_not_skip_actions' do
      assert !@transitions.skip_actions
    end

    it 'should_not_skip_after' do
      assert !@transitions.skip_after
    end

    it 'should_use_transaction' do
      assert @transitions.use_transaction
    end

    it 'should_be_empty' do
      assert @transitions.empty?
    end
  end

  context 'EmptyWithoutBlock' do
    before(:each) do
      @transitions = StateMachines::TransitionCollection.new
      @result = @transitions.perform
    end

    it 'should_succeed' do
      assert_equal true, @result
    end
  end


  context 'EmptyWithBlock' do
    before(:each) do
      @transitions = StateMachines::TransitionCollection.new
    end

    it 'should_raise_exception_if_perform_raises_exception' do
      assert_raise(ArgumentError) { @transitions.perform { raise ArgumentError } }
    end

    it 'should_use_block_result_if_non_boolean' do
      assert_equal 1, @transitions.perform { 1 }
    end

    it 'should_use_block_result_if_false' do
      assert_equal false, @transitions.perform { false }
    end

    it 'should_use_block_reslut_if_nil' do
      assert_equal nil, @transitions.perform { nil }
    end
  end

  context 'Invalid' do
    before(:each) do
      @transitions = StateMachines::TransitionCollection.new([false])
    end

    it 'should_be_empty' do
      assert @transitions.empty?
    end

    it 'should_not_succeed' do
      assert_equal false, @transitions.perform
    end

    it 'should_not_run_perform_block' do
      ran_block = false
      @transitions.perform { ran_block = true }
      assert !ran_block
    end
  end

  context 'PartialInvalid' do
    before(:each) do
      @klass = Class.new do
        attr_accessor :ran_transaction
      end

      @callbacks = []

      @machine = StateMachines::Machine.new(@klass, :initial => :parked)
      @machine.state :idling
      @machine.event :ignite
      @machine.before_transition { @callbacks << :before }
      @machine.after_transition { @callbacks << :after }
      @machine.around_transition { |block| @callbacks << :around_before; block.call; @callbacks << :around_after }

      class << @machine
        def within_transaction(object)
          object.ran_transaction = true
        end
      end

      @object = @klass.new

      @transitions = StateMachines::TransitionCollection.new([
                                                                 StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
                                                                 false
                                                             ])
    end

    it 'should_not_store_invalid_values' do
      assert_equal 1, @transitions.length
    end

    it 'should_not_succeed' do
      assert_equal false, @transitions.perform
    end

    it 'should_not_start_transaction' do
      assert !@object.ran_transaction
    end

    it 'should_not_run_perform_block' do
      ran_block = false
      @transitions.perform { ran_block = true }
      assert !ran_block
    end

    it 'should_not_run_before_callbacks' do
      assert !@callbacks.include?(:before)
    end

    it 'should_not_persist_states' do
      assert_equal 'parked', @object.state
    end

    it 'should_not_run_after_callbacks' do
      assert !@callbacks.include?(:after)
    end

    it 'should_not_run_around_callbacks_before_yield' do
      assert !@callbacks.include?(:around_before)
    end

    it 'should_not_run_around_callbacks_after_yield' do
      assert !@callbacks.include?(:around_after)
    end
  end

  context 'Valid' do
    before(:each) do
      @klass = Class.new do
        attr_reader :persisted

        def initialize
          @persisted = nil
          
          @persisted = []
        end

        def state=(value)
          @persisted << 'state' if @persisted
          @state = value
        end

        def status=(value)
          @persisted << 'status' if @persisted
          @status = value
        end
      end

      @state = StateMachines::Machine.new(@klass, :initial => :parked)
      @state.state :idling
      @state.event :ignite
      @status = StateMachines::Machine.new(@klass, :status, :initial => :first_gear)
      @status.state :second_gear
      @status.event :shift_up

      @object = @klass.new

      @result = StateMachines::TransitionCollection.new([
                                                            @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
                                                            @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
                                                        ]).perform
    end

    it 'should_succeed' do
      assert_equal true, @result
    end

    it 'should_persist_each_state' do
      assert_equal 'idling', @object.state
      assert_equal 'second_gear', @object.status
    end

    it 'should_persist_in_order' do
      assert_equal ['state', 'status'], @object.persisted
    end

    it 'should_store_results_in_transitions' do
      assert_nil @state_transition.result
      assert_nil @status_transition.result
    end
  end

  context 'WithoutTransactions' do
    before(:each) do
      @klass = Class.new do
        attr_accessor :ran_transaction
      end

      @machine = StateMachines::Machine.new(@klass, :initial => :parked)
      @machine.state :idling
      @machine.event :ignite

      class << @machine
        def within_transaction(object)
          object.ran_transaction = true
        end
      end

      @object = @klass.new
      @transitions = StateMachines::TransitionCollection.new([
                                                                 StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                             ], :transaction => false)
      @transitions.perform
    end

    it 'should_not_run_within_transaction' do
      assert !@object.ran_transaction
    end
  end

  context 'WithTransactions' do
    before(:each) do
      @klass = Class.new do
        attr_accessor :running_transaction, :cancelled_transaction
      end

      @machine = StateMachines::Machine.new(@klass, :initial => :parked)
      @machine.state :idling
      @machine.event :ignite

      class << @machine
        def within_transaction(object)
          object.running_transaction = true
          object.cancelled_transaction = yield == false
          object.running_transaction = false
        end
      end

      @object = @klass.new
      @transitions = StateMachines::TransitionCollection.new([
                                                                 StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                             ], :transaction => true)
    end

    it 'should_run_before_callbacks_within_transaction' do
      @machine.before_transition { |object| @in_transaction = object.running_transaction }
      @transitions.perform

      assert @in_transaction
    end

    it 'should_run_action_within_transaction' do
      @transitions.perform { @in_transaction = @object.running_transaction }

      assert @in_transaction
    end

    it 'should_run_after_callbacks_within_transaction' do
      @machine.after_transition { |object| @in_transaction = object.running_transaction }
      @transitions.perform

      assert @in_transaction
    end

    it 'should_cancel_the_transaction_on_before_halt' do
      @machine.before_transition { throw :halt }

      @transitions.perform
      assert @object.cancelled_transaction
    end

    it 'should_cancel_the_transaction_on_action_failure' do
      @transitions.perform { false }
      assert @object.cancelled_transaction
    end

    it 'should_not_cancel_the_transaction_on_after_halt' do
      @machine.after_transition { throw :halt }

      @transitions.perform
      assert !@object.cancelled_transaction
    end
  end

  context 'WithEmptyActions' do
    before(:each) do
      @klass = Class.new

      @state = StateMachines::Machine.new(@klass, :initial => :parked)
      @state.state :idling
      @state.event :ignite

      @status = StateMachines::Machine.new(@klass, :status, :initial => :first_gear)
      @status.state :second_gear
      @status.event :shift_up

      @object = @klass.new

      @transitions = StateMachines::TransitionCollection.new([
                                                                 @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
                                                                 @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
                                                             ])

      @object.state = 'idling'
      @object.status = 'second_gear'

      @result = @transitions.perform
    end

    it 'should_succeed' do
      assert_equal true, @result
    end

    it 'should_persist_states' do
      assert_equal 'idling', @object.state
      assert_equal 'second_gear', @object.status
    end

    it 'should_store_results_in_transitions' do
      assert_nil @state_transition.result
      assert_nil @status_transition.result
    end
  end

  context 'WithSkippedActions' do
    before(:each) do
      @klass = Class.new do
        attr_reader :actions

        def save_state
          (@actions ||= []) << :save_state
          :save_state
        end

        def save_status
          (@actions ||= []) << :save_status
          :save_status
        end
      end

      @callbacks = []

      @state = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save_state)
      @state.state :idling
      @state.event :ignite
      @state.before_transition { @callbacks << :state_before }
      @state.after_transition { @callbacks << :state_after }
      @state.around_transition { |block| @callbacks << :state_around_before; block.call; @callbacks << :state_around_after }

      @status = StateMachines::Machine.new(@klass, :status, :initial => :first_gear, :action => :save_status)
      @status.state :second_gear
      @status.event :shift_up
      @status.before_transition { @callbacks << :status_before }
      @status.after_transition { @callbacks << :status_after }
      @status.around_transition { |block| @callbacks << :status_around_before; block.call; @callbacks << :status_around_after }

      @object = @klass.new

      @transitions = StateMachines::TransitionCollection.new([
                                                                 @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
                                                                 @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
                                                             ], :actions => false)
      @result = @transitions.perform
    end

    it 'should_skip_actions' do
      assert_equal true, @transitions.skip_actions
    end

    it 'should_succeed' do
      assert_equal true, @result
    end

    it 'should_persist_states' do
      assert_equal 'idling', @object.state
      assert_equal 'second_gear', @object.status
    end

    it 'should_not_run_actions' do
      assert_nil @object.actions
    end

    it 'should_store_results_in_transitions' do
      assert_nil @state_transition.result
      assert_nil @status_transition.result
    end

    it 'should_run_all_callbacks' do
      assert_equal [:state_before, :state_around_before, :status_before, :status_around_before, :status_around_after, :status_after, :state_around_after, :state_after], @callbacks
    end
  end

  context 'WithSkippedActionsAndBlock' do
    before(:each) do
      @klass = Class.new

      @machine = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save_state)
      @machine.state :idling
      @machine.event :ignite

      @object = @klass.new

      @transitions = StateMachines::TransitionCollection.new([
                                                                 @state_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                             ], :actions => false)
      @result = @transitions.perform { @ran_block = true; 1 }
    end

    it 'should_succeed' do
      assert_equal 1, @result
    end

    it 'should_persist_states' do
      assert_equal 'idling', @object.state
    end

    it 'should_run_block' do
      assert @ran_block
    end

    it 'should_store_results_in_transitions' do
      assert_equal 1, @state_transition.result
    end
  end

  context 'WithDuplicateActions' do
    before(:each) do
      @klass = Class.new do
        attr_reader :actions

        def save
          (@actions ||= []) << :save
          :save
        end
      end

      @state = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
      @state.state :idling
      @state.event :ignite

      @status = StateMachines::Machine.new(@klass, :status, :initial => :first_gear, :action => :save)
      @status.state :second_gear
      @status.event :shift_up

      @object = @klass.new

      @transitions = StateMachines::TransitionCollection.new([
                                                                 @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
                                                                 @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
                                                             ])
      @result = @transitions.perform
    end

    it 'should_succeed' do
      assert_equal :save, @result
    end

    it 'should_persist_states' do
      assert_equal 'idling', @object.state
      assert_equal 'second_gear', @object.status
    end

    it 'should_run_action_once' do
      assert_equal [:save], @object.actions
    end

    it 'should_store_results_in_transitions' do
      assert_equal :save, @state_transition.result
      assert_equal :save, @status_transition.result
    end
  end

  context 'WithDifferentActions' do
    before(:each) do
      @klass = Class.new do
        attr_reader :actions

        def save_state
          (@actions ||= []) << :save_state
          :save_state
        end

        def save_status
          (@actions ||= []) << :save_status
          :save_status
        end
      end

      @state = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save_state)
      @state.state :idling
      @state.event :ignite

      @status = StateMachines::Machine.new(@klass, :status, :initial => :first_gear, :action => :save_status)
      @status.state :second_gear
      @status.event :shift_up

      @object = @klass.new

      @transitions = StateMachines::TransitionCollection.new([
                                                                 @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
                                                                 @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
                                                             ])
    end

    it 'should_succeed' do
      assert_equal true, @transitions.perform
    end

    it 'should_persist_states' do
      @transitions.perform
      assert_equal 'idling', @object.state
      assert_equal 'second_gear', @object.status
    end

    it 'should_run_actions_in_order' do
      @transitions.perform
      assert_equal [:save_state, :save_status], @object.actions
    end

    it 'should_store_results_in_transitions' do
      @transitions.perform
      assert_equal :save_state, @state_transition.result
      assert_equal :save_status, @status_transition.result
    end

    it 'should_not_halt_if_action_fails_for_first_transition' do
      @klass.class_eval do
        remove_method :save_state

        def save_state
          (@actions ||= []) << :save_state
          false
        end
      end


      assert_equal false, @transitions.perform
      assert_equal [:save_state, :save_status], @object.actions
    end

    it 'should_halt_if_action_fails_for_second_transition' do
      @klass.class_eval do
        remove_method :save_status

        def save_status
          (@actions ||= []) << :save_status
          false
        end
      end

      assert_equal false, @transitions.perform
      assert_equal [:save_state, :save_status], @object.actions
    end

    it 'should_rollback_if_action_errors_for_first_transition' do
      @klass.class_eval do
        remove_method :save_state

        def save_state
          raise ArgumentError
        end
      end

      begin
        ; @transitions.perform;
      rescue;
      end
      assert_equal 'parked', @object.state
      assert_equal 'first_gear', @object.status
    end

    it 'should_rollback_if_action_errors_for_second_transition' do
      @klass.class_eval do
        remove_method :save_status

        def save_status
          raise ArgumentError
        end
      end

      begin
        ; @transitions.perform;
      rescue;
      end
      assert_equal 'parked', @object.state
      assert_equal 'first_gear', @object.status
    end

    it 'should_not_run_after_callbacks_if_action_fails_for_first_transition' do
      @klass.class_eval do
        remove_method :save_state

        def save_state
          false
        end
      end

      @callbacks = []
      @state.after_transition { @callbacks << :state_after }
      @state.around_transition { |block| block.call; @callbacks << :state_around }
      @status.after_transition { @callbacks << :status_after }
      @status.around_transition { |block| block.call; @callbacks << :status_around }

      @transitions.perform
      assert_equal [], @callbacks
    end

    it 'should_not_run_after_callbacks_if_action_fails_for_second_transition' do
      @klass.class_eval do
        remove_method :save_status

        def save_status
          false
        end
      end

      @callbacks = []
      @state.after_transition { @callbacks << :state_after }
      @state.around_transition { |block| block.call; @callbacks << :state_around }
      @status.after_transition { @callbacks << :status_after }
      @status.around_transition { |block| block.call; @callbacks << :status_around }

      @transitions.perform
      assert_equal [], @callbacks
    end

    it 'should_run_after_failure_callbacks_if_action_fails_for_first_transition' do
      @klass.class_eval do
        remove_method :save_state

        def save_state
          false
        end
      end

      @callbacks = []
      @state.after_failure { @callbacks << :state_after }
      @status.after_failure { @callbacks << :status_after }

      @transitions.perform
      assert_equal [:status_after, :state_after], @callbacks
    end

    it 'should_run_after_failure_callbacks_if_action_fails_for_second_transition' do
      @klass.class_eval do
        remove_method :save_status

        def save_status
          false
        end
      end

      @callbacks = []
      @state.after_failure { @callbacks << :state_after }
      @status.after_failure { @callbacks << :status_after }

      @transitions.perform
      assert_equal [:status_after, :state_after], @callbacks
    end
  end

  context 'WithMixedActions' do
    before(:each) do
      @klass = Class.new do
        def save
          true
        end
      end

      @state = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
      @state.state :idling
      @state.event :ignite

      @status = StateMachines::Machine.new(@klass, :status, :initial => :first_gear)
      @status.state :second_gear
      @status.event :shift_up

      @object = @klass.new

      @transitions = StateMachines::TransitionCollection.new([
                                                                 @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
                                                                 @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
                                                             ])
      @result = @transitions.perform
    end

    it 'should_succeed' do
      assert_equal true, @result
    end

    it 'should_persist_states' do
      assert_equal 'idling', @object.state
      assert_equal 'second_gear', @object.status
    end

    it 'should_store_results_in_transitions' do
      assert_equal true, @state_transition.result
      assert_nil @status_transition.result
    end
  end

  context 'WithBlock' do
    before(:each) do
      @klass = Class.new do
        attr_reader :actions

        def save
          (@actions ||= []) << :save
        end
      end

      @state = StateMachines::Machine.new(@klass, :state, :initial => :parked, :action => :save)
      @state.state :idling
      @state.event :ignite

      @status = StateMachines::Machine.new(@klass, :status, :initial => :first_gear, :action => :save)
      @status.state :second_gear
      @status.event :shift_up

      @object = @klass.new
      @transitions = StateMachines::TransitionCollection.new([
                                                                 @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
                                                                 @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
                                                             ])
      @result = @transitions.perform { 1 }
    end

    it 'should_succeed' do
      assert_equal 1, @result
    end

    it 'should_persist_states' do
      assert_equal 'idling', @object.state
      assert_equal 'second_gear', @object.status
    end

    it 'should_not_run_machine_actions' do
      assert_nil @object.actions
    end

    it 'should_use_result_as_transition_result' do
      assert_equal 1, @state_transition.result
      assert_equal 1, @status_transition.result
    end
  end

  context 'WithActionFailed' do
    before(:each) do
      @klass = Class.new do
        def save
          false
        end
      end
      @before_count = 0
      @around_before_count = 0
      @after_count = 0
      @around_after_count = 0
      @failure_count = 0

      @machine = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
      @machine.state :idling
      @machine.event :ignite

      @machine.before_transition { @before_count += 1 }
      @machine.after_transition { @after_count += 1 }
      @machine.around_transition { |block| @around_before_count += 1; block.call; @around_after_count += 1 }
      @machine.after_failure { @failure_count += 1 }

      @object = @klass.new

      @transitions = StateMachines::TransitionCollection.new([
                                                                 StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                             ])
      @result = @transitions.perform
    end

    it 'should_not_succeed' do
      assert_equal false, @result
    end

    it 'should_not_persist_state' do
      assert_equal 'parked', @object.state
    end

    it 'should_run_before_callbacks' do
      assert_equal 1, @before_count
    end

    it 'should_run_around_callbacks_before_yield' do
      assert_equal 1, @around_before_count
    end

    it 'should_not_run_after_callbacks' do
      assert_equal 0, @after_count
    end

    it 'should_not_run_around_callbacks' do
      assert_equal 0, @around_after_count
    end

    it 'should_run_failure_callbacks' do
      assert_equal 1, @failure_count
    end
  end

  context 'WithActionError' do
    before(:each) do
      @klass = Class.new do
        def save
          raise ArgumentError
        end
      end
      @before_count = 0
      @around_before_count = 0
      @after_count = 0
      @around_after_count = 0
      @failure_count = 0

      @machine = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
      @machine.state :idling
      @machine.event :ignite

      @machine.before_transition { @before_count += 1 }
      @machine.after_transition { @after_count += 1 }
      @machine.around_transition { |block| @around_before_count += 1; block.call; @around_after_count += 1 }
      @machine.after_failure { @failure_count += 1 }

      @object = @klass.new

      @transitions = StateMachines::TransitionCollection.new([
                                                                 StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                             ])

      @raised = true
      begin
        @transitions.perform
        @raised = false
      rescue ArgumentError
      end
    end

    it 'should_not_catch_exception' do
      assert @raised
    end

    it 'should_not_persist_state' do
      assert_equal 'parked', @object.state
    end

    it 'should_run_before_callbacks' do
      assert_equal 1, @before_count
    end

    it 'should_run_around_callbacks_before_yield' do
      assert_equal 1, @around_before_count
    end

    it 'should_not_run_after_callbacks' do
      assert_equal 0, @after_count
    end

    it 'should_not_run_around_callbacks_after_yield' do
      assert_equal 0, @around_after_count
    end

    it 'should_not_run_failure_callbacks' do
      assert_equal 0, @failure_count
    end
  end

  context 'WithCallbacks' do
    before(:each) do
      @klass = Class.new do
        attr_reader :saved

        def save
          @saved = true
        end
      end

      @before_callbacks = []
      @after_callbacks = []

      @state = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
      @state.state :idling
      @state.event :ignite
      @state.before_transition { @before_callbacks << :state_before }
      @state.after_transition { @after_callbacks << :state_after }
      @state.around_transition { |block| @before_callbacks << :state_around; block.call; @after_callbacks << :state_around }

      @status = StateMachines::Machine.new(@klass, :status, :initial => :first_gear, :action => :save)
      @status.state :second_gear
      @status.event :shift_up
      @status.before_transition { @before_callbacks << :status_before }
      @status.after_transition { @after_callbacks << :status_after }
      @status.around_transition { |block| @before_callbacks << :status_around; block.call; @after_callbacks << :status_around }

      @object = @klass.new
      @transitions = StateMachines::TransitionCollection.new([
                                                                 StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
                                                                 StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
                                                             ])
    end

    it 'should_run_before_callbacks_in_order' do
      @transitions.perform
      assert_equal [:state_before, :state_around, :status_before, :status_around], @before_callbacks
    end

    it 'should_halt_if_before_callback_halted_for_first_transition' do
      @state.before_transition { throw :halt }

      assert_equal false, @transitions.perform
      assert_equal [:state_before, :state_around], @before_callbacks
    end

    it 'should_halt_if_before_callback_halted_for_second_transition' do
      @status.before_transition { throw :halt }

      assert_equal false, @transitions.perform
      assert_equal [:state_before, :state_around, :status_before, :status_around], @before_callbacks
    end

    it 'should_halt_if_around_callback_halted_before_yield_for_first_transition' do
      @state.around_transition { throw :halt }

      assert_equal false, @transitions.perform
      assert_equal [:state_before, :state_around], @before_callbacks
    end

    it 'should_halt_if_around_callback_halted_before_yield_for_second_transition' do
      @status.around_transition { throw :halt }

      assert_equal false, @transitions.perform
      assert_equal [:state_before, :state_around, :status_before, :status_around], @before_callbacks
    end

    it 'should_run_after_callbacks_in_reverse_order' do
      @transitions.perform
      assert_equal [:status_around, :status_after, :state_around, :state_after], @after_callbacks
    end

    it 'should_not_halt_if_after_callback_halted_for_first_transition' do
      @state.after_transition { throw :halt }

      assert_equal true, @transitions.perform
      assert_equal [:status_around, :status_after, :state_around, :state_after], @after_callbacks
    end

    it 'should_not_halt_if_around_callback_halted_for_second_transition' do
      @status.around_transition { |block| block.call; throw :halt }

      assert_equal true, @transitions.perform
      assert_equal [:state_around, :state_after], @after_callbacks
    end

    it 'should_run_before_callbacks_before_persisting_the_state' do
      @state.before_transition { |object| @before_state = object.state }
      @state.around_transition { |object, transition, block| @around_state = object.state; block.call }
      @transitions.perform

      assert_equal 'parked', @before_state
      assert_equal 'parked', @around_state
    end

    it 'should_persist_state_before_running_action' do
      @klass.class_eval do
        attr_reader :saved_on_persist

        def state=(value)
          @state = value
          @saved_on_persist = saved
        end
      end

      @transitions.perform
      assert !@object.saved_on_persist
    end

    it 'should_persist_state_before_running_action_block' do
      @klass.class_eval do
        attr_writer :saved
        attr_reader :saved_on_persist

        def state=(value)
          @state = value
          @saved_on_persist = saved
        end
      end

      @transitions.perform { @object.saved = true }
      assert !@object.saved_on_persist
    end

    it 'should_run_after_callbacks_after_running_the_action' do
      @state.after_transition { |object| @after_saved = object.saved }
      @state.around_transition { |object, transition, block| block.call; @around_saved = object.saved }
      @transitions.perform

      assert @after_saved
      assert @around_saved
    end
  end

  context 'WithBeforeCallbackHalt' do
    before(:each) do
      @klass = Class.new do
        attr_reader :saved

        def save
          @saved = true
        end
      end
      @before_count = 0
      @after_count = 0

      @machine = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
      @machine.state :idling
      @machine.event :ignite

      @machine.before_transition { @before_count += 1; throw :halt }
      @machine.before_transition { @before_count += 1 }
      @machine.after_transition { @after_count += 1 }
      @machine.around_transition { |block| @before_count += 1; block.call; @after_count += 1 }

      @object = @klass.new

      @transitions = StateMachines::TransitionCollection.new([
                                                                 StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                             ])
      @result = @transitions.perform
    end

    it 'should_not_succeed' do
      assert_equal false, @result
    end

    it 'should_not_persist_state' do
      assert_equal 'parked', @object.state
    end

    it 'should_not_run_action' do
      assert !@object.saved
    end

    it 'should_not_run_further_before_callbacks' do
      assert_equal 1, @before_count
    end

    it 'should_not_run_after_callbacks' do
      assert_equal 0, @after_count
    end
  end

  context 'WithAfterCallbackHalt' do
    before(:each) do
      @klass = Class.new do
        attr_reader :saved

        def save
          @saved = true
        end
      end
      @before_count = 0
      @after_count = 0

      @machine = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
      @machine.state :idling
      @machine.event :ignite

      @machine.before_transition { @before_count += 1 }
      @machine.after_transition { @after_count += 1; throw :halt }
      @machine.after_transition { @after_count += 1 }
      @machine.around_transition { |block| @before_count += 1; block.call; @after_count += 1 }

      @object = @klass.new

      @transitions = StateMachines::TransitionCollection.new([
                                                                 StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                             ])
      @result = @transitions.perform
    end

    it 'should_succeed' do
      assert_equal true, @result
    end

    it 'should_persist_state' do
      assert_equal 'idling', @object.state
    end

    it 'should_run_before_callbacks' do
      assert_equal 2, @before_count
    end

    it 'should_not_run_further_after_callbacks' do
      assert_equal 2, @after_count
    end
  end

  context 'WithSkippedAfterCallbacks' do
    before(:each) do
      @klass = Class.new

      @callbacks = []

      @machine = StateMachines::Machine.new(@klass, :initial => :parked)
      @machine.state :idling
      @machine.event :ignite
      @machine.after_transition { @callbacks << :after }

      @object = @klass.new

      @transitions = StateMachines::TransitionCollection.new([
                                                                 @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                             ], :after => false)
      @result = @transitions.perform
    end

    it 'should_succeed' do
      assert_equal true, @result
    end

    it 'should_not_run_after_callbacks' do
      assert !@callbacks.include?(:after)
    end

    it 'should_run_after_callbacks_on_subsequent_perform' do
      StateMachines::TransitionCollection.new([@transition]).perform
      assert @callbacks.include?(:after)
    end
  end

  if StateMachines::Transition.pause_supported?
    context 'WithSkippedAfterCallbacksAndAroundCallbacks' do
      before(:each) do
        @klass = Class.new

        @callbacks = []

        @machine = StateMachines::Machine.new(@klass, :initial => :parked)
        @machine.state :idling
        @machine.event :ignite
        @machine.around_transition { |block| @callbacks << :around_before; block.call; @callbacks << :around_after }

        @object = @klass.new

        @transitions = StateMachines::TransitionCollection.new([
                                                                   @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                               ], :after => false)
        @result = @transitions.perform
      end

      it 'should_succeed' do
        assert_equal true, @result
      end

      it 'should_not_run_around_callbacks_after_yield' do
        assert !@callbacks.include?(:around_after)
      end

      it 'should_run_around_callbacks_after_yield_on_subsequent_perform' do
        StateMachines::TransitionCollection.new([@transition]).perform
        assert @callbacks.include?(:around_after)
      end

      it 'should_not_rerun_around_callbacks_before_yield_on_subsequent_perform' do
        @callbacks = []
        StateMachines::TransitionCollection.new([@transition]).perform

        assert !@callbacks.include?(:around_before)
      end
    end
  else
    context 'WithSkippedAfterCallbacksAndAroundCallbacks' do
      before(:each) do
        @klass = Class.new

        @callbacks = []

        @machine = StateMachines::Machine.new(@klass, :initial => :parked)
        @machine.state :idling
        @machine.event :ignite
        @machine.around_transition { |block| @callbacks << :around_before; block.call; @callbacks << :around_after }

        @object = @klass.new

        @transitions = StateMachines::TransitionCollection.new([
                                                                   @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                               ], :after => false)
      end

      it 'should_raise_exception' do
        assert_raise(ArgumentError) { @transitions.perform }
      end
    end
  end

  xit 'WithActionHookBase' do
    before(:each) do
      @class = Class.new do
        def save
          true
        end
      end

      @klass = Class.new(@class) do
        attr_reader :saved, :state_on_save, :state_event_on_save, :state_event_transition_on_save

        def save
          @saved = true
          @state_on_save = state
          @state_event_on_save = state_event
          @state_event_transition_on_save = state_event_transition
          
        end
      end

      @machine = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
      @machine.state :idling
      @machine.event :ignite

      @object = @klass.new

      @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    end


    context 'WithActionHookAndSkippedAction' do
      before(:each) do
        @result = StateMachines::TransitionCollection.new([@transition], :actions => false).perform
      end

      it 'should_succeed' do
        assert_equal true, @result
      end

      it 'should_not_run_action' do
        assert !@object.saved
      end
    end

    context 'WithActionHookAndSkippedAfterCallbacks' do
      before(:each) do
        @result = StateMachines::TransitionCollection.new([@transition], :after => false).perform
      end

      it 'should_succeed' do
        assert_equal true, @result
      end

      it 'should_run_action' do
        assert @object.saved
      end

      it 'should_have_already_persisted_when_running_action' do
        assert_equal 'idling', @object.state_on_save
      end

      it 'should_not_have_event_during_action' do
        assert_nil @object.state_event_on_save
      end

      it 'should_not_write_event' do
        assert_nil @object.state_event
      end

      it 'should_not_have_event_transition_during_save' do
        assert_nil @object.state_event_transition_on_save
      end

      it 'should_not_write_event_attribute' do
        assert_nil @object.send(:state_event_transition)
      end
    end

    context 'WithActionHookAndBlock' do
      before(:each) do
        
        @result = StateMachines::TransitionCollection.new([@transition]).perform { true }
      end

      it 'should_succeed' do
        assert_equal true, @result
      end

      it 'should_not_run_action' do
        assert !@object.saved
      end
    end

    context 'WithActionHookInvalid' do
      before(:each) do
        
        @result = StateMachines::TransitionCollection.new([@transition, nil]).perform
      end

      it 'should_not_succeed' do
        assert_equal false, @result
      end

      it 'should_not_run_action' do
        assert !@object.saved
      end
    end

    context 'WithActionHookWithNilAction' do
      before(:each) do
        

        @machine = StateMachines::Machine.new(@klass, :status, :initial => :first_gear)
        @machine.state :second_gear
        @machine.event :shift_up

        @result = StateMachines::TransitionCollection.new([@transition, StateMachines::Transition.new(@object, @machine, :shift_up, :first_gear, :second_gear)]).perform
      end

      it 'should_succeed' do
        assert_equal true, @result
      end

      it 'should_run_action' do
        assert @object.saved
      end

      it 'should_have_already_persisted_when_running_action' do
        assert_equal 'idling', @object.state_on_save
      end

      it 'should_not_have_event_during_action' do
        assert_nil @object.state_event_on_save
      end

      it 'should_not_write_event' do
        assert_nil @object.state_event
      end

      it 'should_not_have_event_transition_during_save' do
        assert_nil @object.state_event_transition_on_save
      end

      it 'should_not_write_event_attribute' do
        assert_nil @object.send(:state_event_transition)
      end
    end

    context 'WithActionHookWithDifferentActions' do
      before(:each) do
        

        @klass.class_eval do
          def save_status
            true
          end
        end

        @machine = StateMachines::Machine.new(@klass, :status, :initial => :first_gear, :action => :save_status)
        @machine.state :second_gear
        @machine.event :shift_up

        @result = StateMachines::TransitionCollection.new([@transition, StateMachines::Transition.new(@object, @machine, :shift_up, :first_gear, :second_gear)]).perform
      end

      it 'should_succeed' do
        assert_equal true, @result
      end

      it 'should_run_action' do
        assert @object.saved
      end

      it 'should_have_already_persisted_when_running_action' do
        assert_equal 'idling', @object.state_on_save
      end

      it 'should_not_have_event_during_action' do
        assert_nil @object.state_event_on_save
      end

      it 'should_not_write_event' do
        assert_nil @object.state_event
      end

      it 'should_not_have_event_transition_during_save' do
        assert_nil @object.state_event_transition_on_save
      end

      it 'should_not_write_event_attribute' do
        assert_nil @object.send(:state_event_transition)
      end
    end

    context 'WithActionHook' do
      before(:each) do
        
        @result = StateMachines::TransitionCollection.new([@transition]).perform
      end

      it 'should_succeed' do
        assert_equal true, @result
      end

      it 'should_run_action' do
        assert @object.saved
      end

      it 'should_not_have_already_persisted_when_running_action' do
        assert_equal 'parked', @object.state_on_save
      end

      it 'should_persist' do
        assert_equal 'idling', @object.state
      end

      it 'should_not_have_event_during_action' do
        assert_nil @object.state_event_on_save
      end

      it 'should_not_write_event' do
        assert_nil @object.state_event
      end

      it 'should_have_event_transition_during_action' do
        assert_equal @transition, @object.state_event_transition_on_save
      end

      it 'should_not_write_event_transition' do
        assert_nil @object.send(:state_event_transition)
      end

      it 'should_mark_event_transition_as_transient' do
        assert @transition.transient?
      end
    end

    context 'WithActionHookMultiple' do
      before(:each) do
        

        @status_machine = StateMachines::Machine.new(@klass, :status, :initial => :first_gear, :action => :save)
        @status_machine.state :second_gear
        @status_machine.event :shift_up

        @klass.class_eval do
          attr_reader :status_on_save, :status_event_on_save, :status_event_transition_on_save

          remove_method :save

          def save
            @saved = true
            @state_on_save = state
            @state_event_on_save = state_event
            @state_event_transition_on_save = state_event_transition
            @status_on_save = status
            @status_event_on_save = status_event
            @status_event_transition_on_save = status_event_transition
            
            1
          end
        end

        @object = @klass.new
        @state_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
        @status_transition = StateMachines::Transition.new(@object, @status_machine, :shift_up, :first_gear, :second_gear)

        @result = StateMachines::TransitionCollection.new([@state_transition, @status_transition]).perform
      end

      it 'should_succeed' do
        assert_equal 1, @result
      end

      it 'should_run_action' do
        assert @object.saved
      end

      it 'should_not_have_already_persisted_when_running_action' do
        assert_equal 'parked', @object.state_on_save
        assert_equal 'first_gear', @object.status_on_save
      end

      it 'should_persist' do
        assert_equal 'idling', @object.state
        assert_equal 'second_gear', @object.status
      end

      it 'should_not_have_events_during_action' do
        assert_nil @object.state_event_on_save
        assert_nil @object.status_event_on_save
      end

      it 'should_not_write_events' do
        assert_nil @object.state_event
        assert_nil @object.status_event
      end

      it 'should_have_event_transitions_during_action' do
        assert_equal @state_transition, @object.state_event_transition_on_save
        assert_equal @status_transition, @object.status_event_transition_on_save
      end

      it 'should_not_write_event_transitions' do
        assert_nil @object.send(:state_event_transition)
        assert_nil @object.send(:status_event_transition)
      end

      it 'should_mark_event_transitions_as_transient' do
        assert @state_transition.transient?
        assert @status_transition.transient?
      end
    end

    context 'WithActionHookError' do
      before(:each) do
        

        @class.class_eval do
          remove_method :save

          def save
            raise ArgumentError
          end
        end

        begin
          ; StateMachines::TransitionCollection.new([@transition]).perform;
        rescue;
        end
      end

      it 'should_not_write_event' do
        assert_nil @object.state_event
      end

      it 'should_not_write_event_transition' do
        assert_nil @object.send(:state_event_transition)
      end
    end

    context 'AttributeTransitionCollectionByDefault' do
      before(:each) do
        @transitions = StateMachines::AttributeTransitionCollection.new
      end

      it 'should_skip_actions' do
        assert @transitions.skip_actions
      end

      it 'should_not_skip_after' do
        assert !@transitions.skip_after
      end

      it 'should_not_use_transaction' do
        assert !@transitions.use_transaction
      end

      it 'should_be_empty' do
        assert @transitions.empty?
      end
    end

    context 'AttributeTransitionCollectionWithEvents' do
      before(:each) do
        @klass = Class.new

        @state = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
        @state.state :idling
        @state.event :ignite

        @status = StateMachines::Machine.new(@klass, :status, :initial => :first_gear, :action => :save)
        @status.state :second_gear
        @status.event :shift_up

        @object = @klass.new
        @object.state_event = 'ignite'
        @object.status_event = 'shift_up'

        @transitions = StateMachines::AttributeTransitionCollection.new([
                                                                            @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
                                                                            @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
                                                                        ])
        @result = @transitions.perform
      end

      it 'should_succeed' do
        assert_equal true, @result
      end

      it 'should_persist_states' do
        assert_equal 'idling', @object.state
        assert_equal 'second_gear', @object.status
      end

      it 'should_clear_events' do
        assert_nil @object.state_event
        assert_nil @object.status_event
      end

      it 'should_not_write_event_transitions' do
        assert_nil @object.send(:state_event_transition)
        assert_nil @object.send(:status_event_transition)
      end
    end

    context 'AttributeTransitionCollectionWithEventTransitions' do
      before(:each) do
        @klass = Class.new

        @state = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
        @state.state :idling
        @state.event :ignite

        @status = StateMachines::Machine.new(@klass, :status, :initial => :first_gear, :action => :save)
        @status.state :second_gear
        @status.event :shift_up

        @object = @klass.new
        @object.send(:state_event_transition=, @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling))
        @object.send(:status_event_transition=, @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear))

        @transitions = StateMachines::AttributeTransitionCollection.new([@state_transition, @status_transition])
        @result = @transitions.perform
      end

      it 'should_succeed' do
        assert_equal true, @result
      end

      it 'should_persist_states' do
        assert_equal 'idling', @object.state
        assert_equal 'second_gear', @object.status
      end

      it 'should_not_write_events' do
        assert_nil @object.state_event
        assert_nil @object.status_event
      end

      it 'should_clear_event_transitions' do
        assert_nil @object.send(:state_event_transition)
        assert_nil @object.send(:status_event_transition)
      end
    end

    context 'AttributeTransitionCollectionWithActionFailed' do
      before(:each) do
        @klass = Class.new

        @state = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
        @state.state :idling
        @state.event :ignite

        @status = StateMachines::Machine.new(@klass, :status, :initial => :first_gear, :action => :save)
        @status.state :second_gear
        @status.event :shift_up

        @object = @klass.new
        @object.state_event = 'ignite'
        @object.status_event = 'shift_up'

        @transitions = StateMachines::AttributeTransitionCollection.new([
                                                                            @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
                                                                            @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
                                                                        ])
        @result = @transitions.perform { false }
      end

      it 'should_not_succeed' do
        assert_equal false, @result
      end

      it 'should_not_persist_states' do
        assert_equal 'parked', @object.state
        assert_equal 'first_gear', @object.status
      end

      it 'should_not_clear_events' do
        assert_equal :ignite, @object.state_event
        assert_equal :shift_up, @object.status_event
      end

      it 'should_not_write_event_transitions' do
        assert_nil @object.send(:state_event_transition)
        assert_nil @object.send(:status_event_transition)
      end
    end

    context 'AttributeTransitionCollectionWithActionError' do
      before(:each) do
        @klass = Class.new

        @state = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
        @state.state :idling
        @state.event :ignite

        @status = StateMachines::Machine.new(@klass, :status, :initial => :first_gear, :action => :save)
        @status.state :second_gear
        @status.event :shift_up

        @object = @klass.new
        @object.state_event = 'ignite'
        @object.status_event = 'shift_up'

        @transitions = StateMachines::AttributeTransitionCollection.new([
                                                                            @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
                                                                            @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
                                                                        ])

        begin
          ; @transitions.perform { raise ArgumentError };
        rescue;
        end
      end

      it 'should_not_persist_states' do
        assert_equal 'parked', @object.state
        assert_equal 'first_gear', @object.status
      end

      it 'should_not_clear_events' do
        assert_equal :ignite, @object.state_event
        assert_equal :shift_up, @object.status_event
      end

      it 'should_not_write_event_transitions' do
        assert_nil @object.send(:state_event_transition)
        assert_nil @object.send(:status_event_transition)
      end
    end

    context 'AttributeTransitionCollectionWithCallbacks' do
      before(:each) do
        @klass = Class.new

        @state = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
        @state.state :idling
        @state.event :ignite

        @status = StateMachines::Machine.new(@klass, :status, :initial => :first_gear, :action => :save)
        @status.state :second_gear
        @status.event :shift_up

        @object = @klass.new

        @transitions = StateMachines::AttributeTransitionCollection.new([
                                                                            @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
                                                                            @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
                                                                        ])
      end

      it 'should_not_have_events_during_before_callbacks' do
        @state.before_transition { |object, transition| @before_state_event = object.state_event }
        @state.around_transition { |object, transition, block| @around_state_event = object.state_event; block.call }
        @transitions.perform

        assert_nil @before_state_event
        assert_nil @around_state_event
      end

      it 'should_not_have_events_during_action' do
        @transitions.perform { @state_event = @object.state_event }

        assert_nil @state_event
      end

      it 'should_not_have_events_during_after_callbacks' do
        @state.after_transition { |object, transition| @after_state_event = object.state_event }
        @state.around_transition { |object, transition, block| block.call; @around_state_event = object.state_event }
        @transitions.perform

        assert_nil @after_state_event
        assert_nil @around_state_event
      end

      it 'should_not_have_event_transitions_during_before_callbacks' do
        @state.before_transition { |object, transition| @state_event_transition = object.send(:state_event_transition) }
        @transitions.perform

        assert_nil @state_event_transition
      end

      it 'should_not_have_event_transitions_during_action' do
        @transitions.perform { @state_event_transition = @object.send(:state_event_transition) }

        assert_nil @state_event_transition
      end

      it 'should_not_have_event_transitions_during_after_callbacks' do
        @state.after_transition { |object, transition| @after_state_event_transition = object.send(:state_event_transition) }
        @state.around_transition { |object, transition, block| block.call; @around_state_event_transition = object.send(:state_event_transition) }
        @transitions.perform

        assert_nil @after_state_event_transition
        assert_nil @around_state_event_transition
      end
    end

    context 'AttributeTransitionCollectionWithBeforeCallbackHalt' do
      before(:each) do
        @klass = Class.new

        @machine = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
        @machine.state :idling
        @machine.event :ignite

        @machine.before_transition { throw :halt }

        @object = @klass.new
        @object.state_event = 'ignite'

        @transitions = StateMachines::AttributeTransitionCollection.new([
                                                                            StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                                        ])
        @result = @transitions.perform
      end

      it 'should_not_succeed' do
        assert_equal false, @result
      end

      it 'should_not_clear_event' do
        assert_equal :ignite, @object.state_event
      end

      it 'should_not_write_event_transition' do
        assert_nil @object.send(:state_event_transition)
      end
    end

    context 'AttributeTransitionCollectionWithBeforeCallbackError' do
      before(:each) do
        @klass = Class.new

        @machine = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
        @machine.state :idling
        @machine.event :ignite

        @machine.before_transition { raise ArgumentError }

        @object = @klass.new
        @object.state_event = 'ignite'

        @transitions = StateMachines::AttributeTransitionCollection.new([
                                                                            StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                                        ])
        begin
          ; @transitions.perform;
        rescue;
        end
      end

      it 'should_not_clear_event' do
        assert_equal :ignite, @object.state_event
      end

      it 'should_not_write_event_transition' do
        assert_nil @object.send(:state_event_transition)
      end
    end

    context 'AttributeTransitionCollectionWithAroundCallbackBeforeYieldHalt' do
      before(:each) do
        @klass = Class.new

        @machine = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
        @machine.state :idling
        @machine.event :ignite

        @machine.around_transition { throw :halt }

        @object = @klass.new
        @object.state_event = 'ignite'

        @transitions = StateMachines::AttributeTransitionCollection.new([
                                                                            StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                                        ])
        @result = @transitions.perform
      end

      it 'should_not_succeed' do
        assert_equal false, @result
      end

      it 'should_not_clear_event' do
        assert_equal :ignite, @object.state_event
      end

      it 'should_not_write_event_transition' do
        assert_nil @object.send(:state_event_transition)
      end
    end

    context 'AttributeTransitionCollectionWithAroundAfterYieldCallbackError' do
      before(:each) do
        @klass = Class.new

        @machine = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
        @machine.state :idling
        @machine.event :ignite

        @machine.before_transition { raise ArgumentError }

        @object = @klass.new
        @object.state_event = 'ignite'

        @transitions = StateMachines::AttributeTransitionCollection.new([
                                                                            StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                                        ])
        begin
          ; @transitions.perform;
        rescue;
        end
      end

      it 'should_not_clear_event' do
        assert_equal :ignite, @object.state_event
      end

      it 'should_not_write_event_transition' do
        assert_nil @object.send(:state_event_transition)
      end
    end

    context 'AttributeTransitionCollectionWithSkippedAfterCallbacks' do
      before(:each) do
        @klass = Class.new

        @state = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
        @state.state :idling
        @state.event :ignite

        @status = StateMachines::Machine.new(@klass, :status, :initial => :first_gear, :action => :save)
        @status.state :second_gear
        @status.event :shift_up

        @object = @klass.new
        @object.state_event = 'ignite'
        @object.status_event = 'shift_up'

        @transitions = StateMachines::AttributeTransitionCollection.new([
                                                                            @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
                                                                            @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
                                                                        ], :after => false)
      end

      it 'should_clear_events' do
        @transitions.perform
        assert_nil @object.state_event
        assert_nil @object.status_event
      end

      it 'should_write_event_transitions_if_success' do
        @transitions.perform { true }
        assert_equal @state_transition, @object.send(:state_event_transition)
        assert_equal @status_transition, @object.send(:status_event_transition)
      end

      it 'should_not_write_event_transitions_if_failed' do
        @transitions.perform { false }
        assert_nil @object.send(:state_event_transition)
        assert_nil @object.send(:status_event_transition)
      end
    end

    context 'AttributeTransitionCollectionWithAfterCallbackHalt' do
      before(:each) do
        @klass = Class.new

        @machine = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
        @machine.state :idling
        @machine.event :ignite

        @machine.after_transition { throw :halt }

        @object = @klass.new
        @object.state_event = 'ignite'

        @transitions = StateMachines::AttributeTransitionCollection.new([
                                                                            StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                                        ])
        @result = @transitions.perform
      end

      it 'should_succeed' do
        assert_equal true, @result
      end

      it 'should_clear_event' do
        assert_nil @object.state_event
      end

      it 'should_not_write_event_transition' do
        assert_nil @object.send(:state_event_transition)
      end
    end

    context 'AttributeTransitionCollectionWithAfterCallbackError' do
      before(:each) do
        @klass = Class.new

        @machine = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
        @machine.state :idling
        @machine.event :ignite

        @machine.after_transition { raise ArgumentError }

        @object = @klass.new
        @object.state_event = 'ignite'

        @transitions = StateMachines::AttributeTransitionCollection.new([
                                                                            StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                                        ])
        begin
          ; @transitions.perform;
        rescue;
        end
      end

      it 'should_clear_event' do
        assert_nil @object.state_event
      end

      it 'should_not_write_event_transition' do
        assert_nil @object.send(:state_event_transition)
      end
    end

    context 'AttributeTransitionCollectionWithAroundCallbackAfterYieldHalt' do
      before(:each) do
        @klass = Class.new

        @machine = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
        @machine.state :idling
        @machine.event :ignite

        @machine.around_transition { |block| block.call; throw :halt }

        @object = @klass.new
        @object.state_event = 'ignite'

        @transitions = StateMachines::AttributeTransitionCollection.new([
                                                                            StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                                        ])
        @result = @transitions.perform
      end

      it 'should_succeed' do
        assert_equal true, @result
      end

      it 'should_clear_event' do
        assert_nil @object.state_event
      end

      it 'should_not_write_event_transition' do
        assert_nil @object.send(:state_event_transition)
      end
    end

    context 'AttributeTransitionCollectionWithAroundCallbackAfterYieldError' do
      before(:each) do
        @klass = Class.new

        @machine = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
        @machine.state :idling
        @machine.event :ignite

        @machine.around_transition { |block| block.call; raise ArgumentError }

        @object = @klass.new
        @object.state_event = 'ignite'

        @transitions = StateMachines::AttributeTransitionCollection.new([
                                                                            StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                                        ])
        begin
          ; @transitions.perform;
        rescue;
        end
      end

      it 'should_clear_event' do
        assert_nil @object.state_event
      end

      it 'should_not_write_event_transition' do
        assert_nil @object.send(:state_event_transition)
      end
    end

    context 'AttributeTransitionCollectionMarshalling' do
      before(:each) do
        @klass = Class.new
        self.class.const_set('Example', @klass)

        @machine = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
        @machine.state :idling
        @machine.event :ignite

        @object = @klass.new
        @object.state_event = 'ignite'
      end

      it 'should_marshal_during_before_callbacks' do
        @machine.before_transition { |object, transition| Marshal.dump(object) }
        assert_nothing_raised do
          transitions(:after => false).perform { true }
          transitions.perform { true }
        end
      end

      it 'should_marshal_during_action' do
        assert_nothing_raised do
          transitions(:after => false).perform do
            Marshal.dump(@object)
            true
          end

          transitions.perform do
            Marshal.dump(@object)
            true
          end
        end
      end

      it 'should_marshal_during_after_callbacks' do
        @machine.after_transition { |object, transition| Marshal.dump(object) }
        assert_nothing_raised do
          transitions(:after => false).perform { true }
          transitions.perform { true }
        end
      end

      if StateMachines::Transition.pause_supported?
        it 'should_marshal_during_around_callbacks_before_yield' do
          @machine.around_transition { |object, transition, block| Marshal.dump(object); block.call }
          assert_nothing_raised do
            transitions(:after => false).perform { true }
            transitions.perform { true }
          end
        end

        it 'should_marshal_during_around_callbacks_after_yield' do
          @machine.around_transition { |object, transition, block| block.call; Marshal.dump(object) }
          assert_nothing_raised do
            transitions(:after => false).perform { true }
            transitions.perform { true }
          end
        end
      end

      after(:each) do
        self.class.send(:remove_const, 'Example')
      end

      private
      def transitions(options = {})
        StateMachines::AttributeTransitionCollection.new([
                                                             StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                         ], options)
      end
    end
  end
end