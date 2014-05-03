require 'spec_helper'

context '' do
  before(:each) do
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_have_an_object' do
    assert_equal @object, @transition.object
  end
  
  it 'should_have_a_machine' do
    assert_equal @machine, @transition.machine
  end
  
  it 'should_have_an_event' do
    assert_equal :ignite, @transition.event
  end
  
  it 'should_have_a_qualified_event' do
    assert_equal :ignite, @transition.qualified_event
  end
  
  it 'should_have_a_human_event' do
    assert_equal 'ignite', @transition.human_event
  end
  
  it 'should_have_a_from_value' do
    assert_equal 'parked', @transition.from
  end
  
  it 'should_have_a_from_name' do
    assert_equal :parked, @transition.from_name
  end
  
  it 'should_have_a_qualified_from_name' do
    assert_equal :parked, @transition.qualified_from_name
  end
  
  it 'should_have_a_human_from_name' do
    assert_equal 'parked', @transition.human_from_name
  end
  
  it 'should_have_a_to_value' do
    assert_equal 'idling', @transition.to
  end
  
  it 'should_have_a_to_name' do
    assert_equal :idling, @transition.to_name
  end
  
  it 'should_have_a_qualified_to_name' do
    assert_equal :idling, @transition.qualified_to_name
  end
  
  it 'should_have_a_human_to_name' do
    assert_equal 'idling', @transition.human_to_name
  end
  
  it 'should_have_an_attribute' do
    assert_equal :state, @transition.attribute
  end
  
  it 'should_not_have_an_action' do
    assert_nil @transition.action
  end
  
  it 'should_not_be_transient' do
    assert_equal false, @transition.transient?
  end
  
  it 'should_generate_attributes' do
    expected = {:object => @object, :attribute => :state, :event => :ignite, :from => 'parked', :to => 'idling'}
    assert_equal expected, @transition.attributes
  end
  
  it 'should_have_empty_args' do
    assert_equal [], @transition.args
  end
  
  it 'should_not_have_a_result' do
    assert_nil @transition.result
  end
  
  it 'should_use_pretty_inspect' do
    assert_equal '#<StateMachines::Transition attribute=:state event=:ignite from="parked" from_name=:parked to="idling" to_name=:idling>', @transition.inspect
  end
end

context 'WithInvalidNodes' do
  before(:each) do
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
  end
  
  it 'should_raise_exception_without_event' do
    assert_raise(IndexError) { StateMachines::Transition.new(@object, @machine, nil, :parked, :idling) }
  end
  
  it 'should_raise_exception_with_invalid_event' do
    assert_raise(IndexError) { StateMachines::Transition.new(@object, @machine, :invalid, :parked, :idling) }
  end
  
  it 'should_raise_exception_with_invalid_from_state' do
    assert_raise(IndexError) { StateMachines::Transition.new(@object, @machine, :ignite, :invalid, :idling) }
  end
  
  it 'should_raise_exception_with_invalid_to_state' do
    assert_raise(IndexError) { StateMachines::Transition.new(@object, @machine, :ignite, :parked, :invalid) }
  end
end

context 'WithDynamicToValue' do
  before(:each) do
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked
    @machine.state :idling, :value => lambda {1}
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_evaluate_to_value' do
    assert_equal 1, @transition.to
  end
end

context 'Loopback' do
  before(:each) do
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked
    @machine.event :park
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :park, :parked, :parked)
  end
  
  it 'should_be_loopback' do
    assert @transition.loopback?
  end
end

context 'WithDifferentStates' do
  before(:each) do
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_not_be_loopback' do
    assert !@transition.loopback?
  end
end

context 'WithNamespace' do
  before(:each) do
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, :namespace => 'alarm')
    @machine.state :off, :active
    @machine.event :activate
    
    @object = @klass.new
    @object.state = 'off'
    
    @transition = StateMachines::Transition.new(@object, @machine, :activate, :off, :active)
  end
  
  it 'should_have_an_event' do
    assert_equal :activate, @transition.event
  end
  
  it 'should_have_a_qualified_event' do
    assert_equal :activate_alarm, @transition.qualified_event
  end
  
  it 'should_have_a_from_name' do
    assert_equal :off, @transition.from_name
  end
  
  it 'should_have_a_qualified_from_name' do
    assert_equal :alarm_off, @transition.qualified_from_name
  end
  
  it 'should_have_a_human_from_name' do
    assert_equal 'off', @transition.human_from_name
  end
  
  it 'should_have_a_to_name' do
    assert_equal :active, @transition.to_name
  end
  
  it 'should_have_a_qualified_to_name' do
    assert_equal :alarm_active, @transition.qualified_to_name
  end
  
  it 'should_have_a_human_to_name' do
    assert_equal 'active', @transition.human_to_name
  end
end

context 'WithCustomMachineAttribute' do
  before(:each) do
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, :state, :attribute => :state_id)
    @machine.state :off, :value => 1
    @machine.state :active, :value => 2
    @machine.event :activate
    
    @object = @klass.new
    @object.state_id = 1
    
    @transition = StateMachines::Transition.new(@object, @machine, :activate, :off, :active)
  end
  
  it 'should_persist' do
    @transition.persist
    assert_equal 2, @object.state_id
  end
  
  it 'should_rollback' do
    @object.state_id = 2
    @transition.rollback
    
    assert_equal 1, @object.state_id
  end
end

context 'WithoutReadingState' do
  before(:each) do
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'idling'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling, false)
  end
  
  it 'should_not_read_from_value_from_object' do
    assert_equal 'parked', @transition.from
  end
  
  it 'should_have_to_value' do
    assert_equal 'idling', @transition.to
  end
end

context 'WithAction' do
  before(:each) do
    @klass = Class.new do
      def save
      end
    end
    
    @machine = StateMachines::Machine.new(@klass, :action => :save)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_have_an_action' do
    assert_equal :save, @transition.action
  end
  
  it 'should_not_have_a_result' do
    assert_nil @transition.result
  end
end

context 'AfterBeingPersisted' do
  before(:each) do
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, :action => :save)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    @transition.persist
  end
  
  it 'should_update_state_value' do
    assert_equal 'idling', @object.state
  end
  
  it 'should_not_change_from_state' do
    assert_equal 'parked', @transition.from
  end
  
  it 'should_not_change_to_state' do
    assert_equal 'idling', @transition.to
  end
  
  it 'should_not_be_able_to_persist_twice' do
    @object.state = 'parked'
    @transition.persist
    assert_equal 'parked', @object.state
  end
  
  it 'should_be_able_to_persist_again_after_resetting' do
    @object.state = 'parked'
    @transition.reset
    @transition.persist
    assert_equal 'idling', @object.state
  end
  
  it 'should_revert_to_from_state_on_rollback' do
    @transition.rollback
    assert_equal 'parked', @object.state
  end
end

context 'AfterBeingRolledBack' do
  before(:each) do
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, :action => :save)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    @object.state = 'idling'
    
    @transition.rollback
  end
  
  it 'should_update_state_value_to_from_state' do
    assert_equal 'parked', @object.state
  end
  
  it 'should_not_change_from_state' do
    assert_equal 'parked', @transition.from
  end
  
  it 'should_not_change_to_state' do
    assert_equal 'idling', @transition.to
  end
  
  it 'should_still_be_able_to_persist' do
    @transition.persist
    assert_equal 'idling', @object.state
  end
end

context 'WithoutCallbacks' do
  before(:each) do
    @klass = Class.new
    
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_succeed' do
    assert_equal true, @transition.run_callbacks
  end
  
  it 'should_succeed_if_after_callbacks_skipped' do
    assert_equal true, @transition.run_callbacks(:after => false)
  end
  
  it 'should_call_block_if_provided' do
    @transition.run_callbacks { @ran_block = true; {} }
    assert @ran_block
  end
  
  it 'should_track_block_result' do
    @transition.run_callbacks {{:result => 1}}
    assert_equal 1, @transition.result
  end
end

context 'WithBeforeCallbacks' do
  before(:each) do
    @klass = Class.new
    
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_run_before_callbacks' do
    @machine.before_transition {@run = true}
    result = @transition.run_callbacks
    
    assert_equal true, result
    assert_equal true, @run
  end
  
  it 'should_only_run_those_that_match_transition_context' do
    @count = 0
    callback = lambda {@count += 1}
    
    @machine.before_transition :from => :parked, :to => :idling, :on => :park, :do => callback
    @machine.before_transition :from => :parked, :to => :parked, :on => :park, :do => callback
    @machine.before_transition :from => :parked, :to => :idling, :on => :ignite, :do => callback
    @machine.before_transition :from => :idling, :to => :idling, :on => :park, :do => callback
    @transition.run_callbacks
    
    assert_equal 1, @count
  end
  
  it 'should_pass_transition_as_argument' do
    @machine.before_transition {|*args| @args = args}
    @transition.run_callbacks
    
    assert_equal [@object, @transition], @args
  end
  
  it 'should_catch_halts' do
    @machine.before_transition {throw :halt}
    
    result = nil
    assert_nothing_thrown { result = @transition.run_callbacks }
    assert_equal false, result
  end
  
  it 'should_not_catch_exceptions' do
    @machine.before_transition {raise ArgumentError}
    assert_raise(ArgumentError) { @transition.run_callbacks }
  end
  
  it 'should_not_be_able_to_run_twice' do
    @count = 0
    @machine.before_transition {@count += 1}
    @transition.run_callbacks
    @transition.run_callbacks
    assert_equal 1, @count
  end
  
  it 'should_be_able_to_run_again_after_halt' do
    @count = 0
    @machine.before_transition {@count += 1; throw :halt}
    @transition.run_callbacks
    @transition.run_callbacks
    assert_equal 2, @count
  end
  
  it 'should_be_able_to_run_again_after_resetting' do
    @count = 0
    @machine.before_transition {@count += 1}
    @transition.run_callbacks
    @transition.reset
    @transition.run_callbacks
    assert_equal 2, @count
  end
  
  it 'should_succeed_if_block_result_is_false' do
    @machine.before_transition {@run = true}
    assert_equal true, @transition.run_callbacks {{:result => false}}
    assert @run
  end
  
  it 'should_succeed_if_block_result_is_true' do
    @machine.before_transition {@run = true}
    assert_equal true, @transition.run_callbacks {{:result => true}}
    assert @run
  end
  
  it 'should_succeed_if_block_success_is_false' do
    @machine.before_transition {@run = true}
    assert_equal true, @transition.run_callbacks {{:success => false}}
    assert @run
  end
  
  it 'should_succeed_if_block_success_is_true' do
    @machine.before_transition {@run = true}
    assert_equal true, @transition.run_callbacks {{:success => true}}
    assert @run
  end
end

context 'WithMultipleBeforeCallbacks' do
  before(:each) do
    @klass = Class.new
    
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_run_in_the_order_they_were_defined' do
    @callbacks = []
    @machine.before_transition {@callbacks << 1}
    @machine.before_transition {@callbacks << 2}
    @transition.run_callbacks
    
    assert_equal [1, 2], @callbacks
  end
  
  it 'should_not_run_further_callbacks_if_halted' do
    @callbacks = []
    @machine.before_transition {@callbacks << 1; throw :halt}
    @machine.before_transition {@callbacks << 2}
    
    assert_equal false, @transition.run_callbacks
    assert_equal [1], @callbacks
  end
  
  it 'should_fail_if_any_callback_halted' do
    @machine.before_transition {true}
    @machine.before_transition {throw :halt}
    
    assert_equal false, @transition.run_callbacks
  end
end

context 'WithAfterCallbacks' do
  before(:each) do
    @klass = Class.new
    
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_run_after_callbacks' do
    @machine.after_transition {|object| @run = true}
    result = @transition.run_callbacks
    
    assert_equal true, result
    assert_equal true, @run
  end
  
  it 'should_only_run_those_that_match_transition_context' do
    @count = 0
    callback = lambda {@count += 1}
    
    @machine.after_transition :from => :parked, :to => :idling, :on => :park, :do => callback
    @machine.after_transition :from => :parked, :to => :parked, :on => :park, :do => callback
    @machine.after_transition :from => :parked, :to => :idling, :on => :ignite, :do => callback
    @machine.after_transition :from => :idling, :to => :idling, :on => :park, :do => callback
    @transition.run_callbacks
    
    assert_equal 1, @count
  end
  
  it 'should_not_run_if_not_successful' do
    @run = false
    @machine.after_transition {|object| @run = true}
    @transition.run_callbacks {{:success => false}}
    assert !@run
  end
  
  it 'should_run_if_successful' do
    @machine.after_transition {|object| @run = true}
    @transition.run_callbacks {{:success => true}}
    assert @run
  end
  
  it 'should_pass_transition_as_argument' do
    @machine.after_transition {|*args| @args = args}
    
    @transition.run_callbacks
    assert_equal [@object, @transition], @args
  end
  
  it 'should_catch_halts' do
    @machine.after_transition {throw :halt}
    
    result = nil
    assert_nothing_thrown { result = @transition.run_callbacks }
    assert_equal true, result
  end
  
  it 'should_not_catch_exceptions' do
    @machine.after_transition {raise ArgumentError}
    assert_raise(ArgumentError) { @transition.run_callbacks }
  end
  
  it 'should_not_be_able_to_run_twice' do
    @count = 0
    @machine.after_transition {@count += 1}
    @transition.run_callbacks
    @transition.run_callbacks
    assert_equal 1, @count
  end
  
  it 'should_not_be_able_to_run_twice_if_halted' do
    @count = 0
    @machine.after_transition {@count += 1; throw :halt}
    @transition.run_callbacks
    @transition.run_callbacks
    assert_equal 1, @count
  end
  
  it 'should_be_able_to_run_again_after_resetting' do
    @count = 0
    @machine.after_transition {@count += 1}
    @transition.run_callbacks
    @transition.reset
    @transition.run_callbacks
    assert_equal 2, @count
  end
end

context 'WithMultipleAfterCallbacks' do
  before(:each) do
    @klass = Class.new
    
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_run_in_the_order_they_were_defined' do
    @callbacks = []
    @machine.after_transition {@callbacks << 1}
    @machine.after_transition {@callbacks << 2}
    @transition.run_callbacks
    
    assert_equal [1, 2], @callbacks
  end
  
  it 'should_not_run_further_callbacks_if_halted' do
    @callbacks = []
    @machine.after_transition {@callbacks << 1; throw :halt}
    @machine.after_transition {@callbacks << 2}
    
    assert_equal true, @transition.run_callbacks
    assert_equal [1], @callbacks
  end
  
  it 'should_fail_if_any_callback_halted' do
    @machine.after_transition {true}
    @machine.after_transition {throw :halt}
    
    assert_equal true, @transition.run_callbacks
  end
end

context 'WithAroundCallbacks' do
  before(:each) do
    @klass = Class.new
    
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_run_around_callbacks' do
    @machine.around_transition {|object, transition, block| @run_before = true; block.call; @run_after = true}
    result = @transition.run_callbacks
    
    assert_equal true, result
    assert_equal true, @run_before
    assert_equal true, @run_after
  end
  
  it 'should_only_run_those_that_match_transition_context' do
    @count = 0
    callback = lambda {|object, transition, block| @count += 1; block.call}
    
    @machine.around_transition :from => :parked, :to => :idling, :on => :park, :do => callback
    @machine.around_transition :from => :parked, :to => :parked, :on => :park, :do => callback
    @machine.around_transition :from => :parked, :to => :idling, :on => :ignite, :do => callback
    @machine.around_transition :from => :idling, :to => :idling, :on => :park, :do => callback
    @transition.run_callbacks
    
    assert_equal 1, @count
  end
  
  it 'should_pass_transition_as_argument' do
    @machine.around_transition {|*args| block = args.pop; @args = args; block.call}
    @transition.run_callbacks
    
    assert_equal [@object, @transition], @args
  end
  
  it 'should_run_block_between_callback' do
    @callbacks = []
    @machine.around_transition {|block| @callbacks << :before; block.call; @callbacks << :after}
    @transition.run_callbacks { @callbacks << :within; {:success => true} }
    
    assert_equal [:before, :within, :after], @callbacks
  end
  
  it 'should_have_access_to_result_after_yield' do
    @machine.around_transition {|block| @before_result = @transition.result; block.call; @after_result = @transition.result}
    @transition.run_callbacks {{:result => 1, :success => true}}
    
    assert_nil @before_result
    assert_equal 1, @after_result
  end
  
  it 'should_catch_before_yield_halts' do
    @machine.around_transition {throw :halt}
    
    result = nil
    assert_nothing_thrown { result = @transition.run_callbacks }
    assert_equal false, result
  end
  
  it 'should_catch_after_yield_halts' do
    @machine.around_transition {|block| block.call; throw :halt}
    
    result = nil
    assert_nothing_thrown { result = @transition.run_callbacks }
    assert_equal true, result
  end
  
  it 'should_not_catch_before_yield' do
    @machine.around_transition {raise ArgumentError}
    assert_raise(ArgumentError) { @transition.run_callbacks }
  end
  
  it 'should_not_catch_after_yield' do
    @machine.around_transition {|block| block.call; raise ArgumentError}
    assert_raise(ArgumentError) { @transition.run_callbacks }
  end
  
  it 'should_fail_if_not_yielded' do
    @machine.around_transition {}
    
    result = nil
    assert_nothing_thrown { result = @transition.run_callbacks }
    assert_equal false, result
  end
  
  it 'should_not_be_able_to_run_twice' do
    @before_count = 0
    @after_count = 0
    @machine.around_transition {|block| @before_count += 1; block.call; @after_count += 1}
    @transition.run_callbacks
    @transition.run_callbacks
    assert_equal 1, @before_count
    assert_equal 1, @after_count
  end
  
  it 'should_be_able_to_run_again_after_resetting' do
    @before_count = 0
    @after_count = 0
    @machine.around_transition {|block| @before_count += 1; block.call; @after_count += 1}
    @transition.run_callbacks
    @transition.reset
    @transition.run_callbacks
    assert_equal 2, @before_count
    assert_equal 2, @after_count
  end
  
  it 'should_succeed_if_block_result_is_false' do
    @machine.around_transition {|block| @before_run = true; block.call; @after_run = true}
    assert_equal true, @transition.run_callbacks {{:success => true, :result => false}}
    assert @before_run
    assert @after_run
  end
  
  it 'should_succeed_if_block_result_is_true' do
    @machine.around_transition {|block| @before_run = true; block.call; @after_run = true}
    assert_equal true, @transition.run_callbacks {{:success => true, :result => true}}
    assert @before_run
    assert @after_run
  end
  
  it 'should_only_run_before_if_block_success_is_false' do
    @after_run = false
    @machine.around_transition {|block| @before_run = true; block.call; @after_run = true}
    assert_equal true, @transition.run_callbacks {{:success => false}}
    assert @before_run
    assert !@after_run
  end
  
  it 'should_succeed_if_block_success_is_false' do
    @machine.around_transition {|block| @before_run = true; block.call; @after_run = true}
    assert_equal true, @transition.run_callbacks {{:success => true}}
    assert @before_run
    assert @after_run
  end
end

context 'WithMultipleAroundCallbacks' do
  before(:each) do
    @klass = Class.new
    
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_before_yield_in_the_order_they_were_defined' do
    @callbacks = []
    @machine.around_transition {|block| @callbacks << 1; block.call}
    @machine.around_transition {|block| @callbacks << 2; block.call}
    @transition.run_callbacks
    
    assert_equal [1, 2], @callbacks
  end
  
  it 'should_before_yield_multiple_methods_in_the_order_they_were_defined' do
    @callbacks = []
    @machine.around_transition(lambda {|block| @callbacks << 1; block.call}, lambda {|block| @callbacks << 2; block.call})
    @machine.around_transition(lambda {|block| @callbacks << 3; block.call}, lambda {|block| @callbacks << 4; block.call})
    @transition.run_callbacks
    
    assert_equal [1, 2, 3, 4], @callbacks
  end
  
  it 'should_after_yield_in_the_reverse_order_they_were_defined' do
    @callbacks = []
    @machine.around_transition {|block| block.call; @callbacks << 1}
    @machine.around_transition {|block| block.call; @callbacks << 2}
    @transition.run_callbacks
    
    assert_equal [2, 1], @callbacks
  end
  
  it 'should_after_yield_multiple_methods_in_the_reverse_order_they_were_defined' do
    @callbacks = []
    @machine.around_transition(lambda {|block| block.call; @callbacks << 1}) {|block| block.call; @callbacks << 2}
    @machine.around_transition(lambda {|block| block.call; @callbacks << 3}) {|block| block.call; @callbacks << 4}
    @transition.run_callbacks
    
    assert_equal [4, 3, 2, 1], @callbacks
  end
  
  it 'should_run_block_between_callback' do
    @callbacks = []
    @machine.around_transition {|block| @callbacks << :before_1; block.call; @callbacks << :after_1}
    @machine.around_transition {|block| @callbacks << :before_2; block.call; @callbacks << :after_2}
    @transition.run_callbacks { @callbacks << :within; {:success => true} }
    
    assert_equal [:before_1, :before_2, :within, :after_2, :after_1], @callbacks
  end
  
  it 'should_have_access_to_result_after_yield' do
    @machine.around_transition {|block| @before_result_1 = @transition.result; block.call; @after_result_1 = @transition.result}
    @machine.around_transition {|block| @before_result_2 = @transition.result; block.call; @after_result_2 = @transition.result}
    @transition.run_callbacks {{:result => 1, :success => true}}
    
    assert_nil @before_result_1
    assert_nil @before_result_2
    assert_equal 1, @after_result_1
    assert_equal 1, @after_result_2
  end
  
  it 'should_fail_if_any_before_yield_halted' do
    @machine.around_transition {|block| block.call}
    @machine.around_transition {throw :halt}
    
    assert_equal false, @transition.run_callbacks
  end
  
  it 'should_not_continue_around_callbacks_if_before_yield_halted' do
    @callbacks = []
    @machine.around_transition {@callbacks << 1; throw :halt}
    @machine.around_transition {|block| @callbacks << 2; block.call; @callbacks << 3}
    
    assert_equal false, @transition.run_callbacks
    assert_equal [1], @callbacks
  end
  
  it 'should_not_continue_around_callbacks_if_later_before_yield_halted' do
    @callbacks = []
    @machine.around_transition {|block| block.call; @callbacks << 1}
    @machine.around_transition {throw :halt}
    
    @transition.run_callbacks
    assert_equal [], @callbacks
  end
  
  it 'should_not_run_further_callbacks_if_after_yield_halted' do
    @callbacks = []
    @machine.around_transition {|block| block.call; @callbacks << 1}
    @machine.around_transition {|block| block.call; throw :halt}
    
    assert_equal true, @transition.run_callbacks
    assert_equal [], @callbacks
  end
  
  it 'should_fail_if_any_fail_to_yield' do
    @callbacks = []
    @machine.around_transition {@callbacks << 1}
    @machine.around_transition {|block| @callbacks << 2; block.call; @callbacks << 3}
    
    assert_equal false, @transition.run_callbacks
    assert_equal [1], @callbacks
  end
end

context 'WithFailureCallbacks' do
  before(:each) do
    @klass = Class.new
    
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_only_run_those_that_match_transition_context' do
    @count = 0
    callback = lambda {@count += 1}
    
    @machine.after_failure :do => callback
    @machine.after_failure :on => :park, :do => callback
    @machine.after_failure :on => :ignite, :do => callback
    @transition.run_callbacks {{:success => false}}
    
    assert_equal 2, @count
  end
  
  it 'should_run_if_not_successful' do
    @machine.after_failure {|object| @run = true}
    @transition.run_callbacks {{:success => false}}
    assert @run
  end
  
  it 'should_not_run_if_successful' do
    @run = false
    @machine.after_failure {|object| @run = true}
    @transition.run_callbacks {{:success => true}}
    assert !@run
  end
  
  it 'should_pass_transition_as_argument' do
    @machine.after_failure {|*args| @args = args}
    
    @transition.run_callbacks {{:success => false}}
    assert_equal [@object, @transition], @args
  end
  
  it 'should_catch_halts' do
    @machine.after_failure {throw :halt}
    
    result = nil
    assert_nothing_thrown { result = @transition.run_callbacks {{:success => false}} }
    assert_equal true, result
  end
  
  it 'should_not_catch_exceptions' do
    @machine.after_failure {raise ArgumentError}
    assert_raise(ArgumentError) { @transition.run_callbacks {{:success => false}} }
  end
  
  it 'should_not_be_able_to_run_twice' do
    @count = 0
    @machine.after_failure {@count += 1}
    @transition.run_callbacks {{:success => false}}
    @transition.run_callbacks {{:success => false}}
    assert_equal 1, @count
  end
  
  it 'should_not_be_able_to_run_twice_if_halted' do
    @count = 0
    @machine.after_failure {@count += 1; throw :halt}
    @transition.run_callbacks {{:success => false}}
    @transition.run_callbacks {{:success => false}}
    assert_equal 1, @count
  end
  
  it 'should_be_able_to_run_again_after_resetting' do
    @count = 0
    @machine.after_failure {@count += 1}
    @transition.run_callbacks {{:success => false}}
    @transition.reset
    @transition.run_callbacks {{:success => false}}
    assert_equal 2, @count
  end
end

context 'WithMultipleFailureCallbacks' do
  before(:each) do
    @klass = Class.new
    
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_run_in_the_order_they_were_defined' do
    @callbacks = []
    @machine.after_failure {@callbacks << 1}
    @machine.after_failure {@callbacks << 2}
    @transition.run_callbacks {{:success => false}}
    
    assert_equal [1, 2], @callbacks
  end
  
  it 'should_not_run_further_callbacks_if_halted' do
    @callbacks = []
    @machine.after_failure {@callbacks << 1; throw :halt}
    @machine.after_failure {@callbacks << 2}
    
    assert_equal true, @transition.run_callbacks {{:success => false}}
    assert_equal [1], @callbacks
  end
  
  it 'should_fail_if_any_callback_halted' do
    @machine.after_failure {true}
    @machine.after_failure {throw :halt}
    
    assert_equal true, @transition.run_callbacks {{:success => false}}
  end
end

context 'WithMixedCallbacks' do
  before(:each) do
    @klass = Class.new
    
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_before_and_around_callbacks_in_order_defined' do
    @callbacks = []
    @machine.before_transition {@callbacks << :before_1}
    @machine.around_transition {|block| @callbacks << :around; block.call}
    @machine.before_transition {@callbacks << :before_2}
    
    assert_equal true, @transition.run_callbacks
    assert_equal [:before_1, :around, :before_2], @callbacks
  end
  
  it 'should_run_around_callbacks_before_after_callbacks' do
    @callbacks = []
    @machine.after_transition {@callbacks << :after_1}
    @machine.around_transition {|block| block.call; @callbacks << :after_2}
    @machine.after_transition {@callbacks << :after_3}
    
    assert_equal true, @transition.run_callbacks
    assert_equal [:after_2, :after_1, :after_3], @callbacks
  end
  
  it 'should_have_access_to_result_for_both_after_and_around_callbacks' do
    @machine.after_transition {@after_result = @transition.result}
    @machine.around_transition {|block| block.call; @around_result = @transition.result}
    
    @transition.run_callbacks {{:result => 1, :success => true}}
    assert_equal 1, @after_result
    assert_equal 1, @around_result
  end
  
  it 'should_not_run_further_callbacks_if_before_callback_halts' do
    @callbacks = []
    @machine.before_transition {@callbacks << :before_1}
    @machine.around_transition {|block| @callbacks << :before_around_1; block.call; @callbacks << :after_around_1}
    @machine.before_transition {@callbacks << :before_2; throw :halt}
    @machine.around_transition {|block| @callbacks << :before_around_2; block.call; @callbacks << :after_around_2}
    @machine.after_transition {@callbacks << :after}
    
    assert_equal false, @transition.run_callbacks
    assert_equal [:before_1, :before_around_1, :before_2], @callbacks
  end
  
  it 'should_not_run_further_callbacks_if_before_yield_halts' do
    @callbacks = []
    @machine.before_transition {@callbacks << :before_1}
    @machine.around_transition {|block| @callbacks << :before_around_1; throw :halt}
    @machine.before_transition {@callbacks << :before_2; throw :halt}
    @machine.around_transition {|block| @callbacks << :before_around_2; block.call; @callbacks << :after_around_2}
    @machine.after_transition {@callbacks << :after}
    
    assert_equal false, @transition.run_callbacks
    assert_equal [:before_1, :before_around_1], @callbacks
  end
  
  it 'should_not_run_further_callbacks_if_around_callback_fails_to_yield' do
    @callbacks = []
    @machine.before_transition {@callbacks << :before_1}
    @machine.around_transition {|block| @callbacks << :before_around_1}
    @machine.before_transition {@callbacks << :before_2; throw :halt}
    @machine.around_transition {|block| @callbacks << :before_around_2; block.call; @callbacks << :after_around_2}
    @machine.after_transition {@callbacks << :after}
    
    assert_equal false, @transition.run_callbacks
    assert_equal [:before_1, :before_around_1], @callbacks
  end
  
  it 'should_not_run_further_callbacks_if_after_yield_halts' do
    @callbacks = []
    @machine.before_transition {@callbacks << :before_1}
    @machine.around_transition {|block| @callbacks << :before_around_1; block.call; @callbacks << :after_around_1; throw :halt}
    @machine.before_transition {@callbacks << :before_2}
    @machine.around_transition {|block| @callbacks << :before_around_2; block.call; @callbacks << :after_around_2}
    @machine.after_transition {@callbacks << :after}
    
    assert_equal true, @transition.run_callbacks
    assert_equal [:before_1, :before_around_1, :before_2, :before_around_2, :after_around_2, :after_around_1], @callbacks
  end
  
  it 'should_not_run_further_callbacks_if_after_callback_halts' do
    @callbacks = []
    @machine.before_transition {@callbacks << :before_1}
    @machine.around_transition {|block| @callbacks << :before_around_1; block.call; @callbacks << :after_around_1}
    @machine.before_transition {@callbacks << :before_2}
    @machine.around_transition {|block| @callbacks << :before_around_2; block.call; @callbacks << :after_around_2}
    @machine.after_transition {@callbacks << :after_1; throw :halt}
    @machine.after_transition {@callbacks << :after_2}
    
    assert_equal true, @transition.run_callbacks
    assert_equal [:before_1, :before_around_1, :before_2, :before_around_2, :after_around_2, :after_around_1, :after_1], @callbacks
  end
end

context 'WithBeforeCallbacksSkipped' do
  before(:each) do
    @klass = Class.new
    
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_not_run_before_callbacks' do
    @run = false
    @machine.before_transition {@run = true}
    
    assert_equal false, @transition.run_callbacks(:before => false)
    assert !@run
  end
  
  it 'should_run_failure_callbacks' do
    @machine.after_failure {@run = true}
    
    assert_equal false, @transition.run_callbacks(:before => false)
    assert @run
  end
end

context 'WithAfterCallbacksSkipped' do
  before(:each) do
    @klass = Class.new
    
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_run_before_callbacks' do
    @machine.before_transition {@run = true}
    
    assert_equal true, @transition.run_callbacks(:after => false)
    assert @run
  end
  
  it 'should_not_run_after_callbacks' do
    @run = false
    @machine.after_transition {@run = true}
    
    assert_equal true, @transition.run_callbacks(:after => false)
    assert !@run
  end
  
  if StateMachines::Transition.pause_supported?
    it 'should_run_around_callbacks_before_yield' do
      @machine.around_transition {|block| @run = true; block.call}
      
      assert_equal true, @transition.run_callbacks(:after => false)
      assert @run
    end
    
    it 'should_not_run_around_callbacks_after_yield' do
      @run = false
      @machine.around_transition {|block| block.call; @run = true}
      
      assert_equal true, @transition.run_callbacks(:after => false)
      assert !@run
    end
    
    it 'should_continue_around_transition_execution_on_second_call' do
      @callbacks = []
      @machine.around_transition {|block| @callbacks << :before_around_1; block.call; @callbacks << :after_around_1}
      @machine.around_transition {|block| @callbacks << :before_around_2; block.call; @callbacks << :after_around_2}
      @machine.after_transition {@callbacks << :after}
      
      assert_equal true, @transition.run_callbacks(:after => false)
      assert_equal [:before_around_1, :before_around_2], @callbacks
      
      assert_equal true, @transition.run_callbacks
      assert_equal [:before_around_1, :before_around_2, :after_around_2, :after_around_1, :after], @callbacks
    end
    
    it 'should_not_run_further_callbacks_if_halted_during_continue_around_transition' do
      @callbacks = []
      @machine.around_transition {|block| @callbacks << :before_around_1; block.call; @callbacks << :after_around_1}
      @machine.around_transition {|block| @callbacks << :before_around_2; block.call; @callbacks << :after_around_2; throw :halt}
      @machine.after_transition {@callbacks << :after}
      
      assert_equal true, @transition.run_callbacks(:after => false)
      assert_equal [:before_around_1, :before_around_2], @callbacks
      
      assert_equal true, @transition.run_callbacks
      assert_equal [:before_around_1, :before_around_2, :after_around_2], @callbacks
    end
    
    it 'should_not_be_able_to_continue_twice' do
      @count = 0
      @machine.around_transition {|block| block.call; @count += 1}
      @machine.after_transition {@count += 1}
      
      @transition.run_callbacks(:after => false)
      
      2.times do
        assert_equal true, @transition.run_callbacks
        assert_equal 2, @count
      end
    end
    
    it 'should_not_be_able_to_continue_again_after_halted' do
      @count = 0
      @machine.around_transition {|block| block.call; @count += 1; throw :halt}
      @machine.after_transition {@count += 1}
      
      @transition.run_callbacks(:after => false)
      
      2.times do
        assert_equal true, @transition.run_callbacks
        assert_equal 1, @count
      end
    end
    
    it 'should_have_access_to_result_after_continued' do
      @machine.around_transition {|block| @around_before_result = @transition.result; block.call; @around_after_result = @transition.result}
      @machine.after_transition {@after_result = @transition.result}
      
      @transition.run_callbacks(:after => false)
      @transition.run_callbacks {{:result => 1}}
      
      assert_nil @around_before_result
      assert_equal 1, @around_after_result
      assert_equal 1, @after_result
    end
    
    it 'should_raise_exceptions_during_around_callbacks_after_yield_in_second_execution' do
      @machine.around_transition {|block| block.call; raise ArgumentError}
      
      assert_nothing_raised { @transition.run_callbacks(:after => false) }
      assert_raise(ArgumentError) { @transition.run_callbacks }
    end
  else
    it 'should_raise_exception_on_second_call' do
      @callbacks = []
      @machine.around_transition {|block| @callbacks << :before_around_1; block.call; @callbacks << :after_around_1}
      @machine.around_transition {|block| @callbacks << :before_around_2; block.call; @callbacks << :after_around_2}
      @machine.after_transition {@callbacks << :after}
      
      assert_raise(ArgumentError) { @transition.run_callbacks(:after => false) }
    end
  end
end

context 'AfterBeingPerformed' do
  before(:each) do
    @klass = Class.new do
      attr_reader :saved, :save_state
      
      def save
        @save_state = state
        @saved = true
        1
      end
    end
    
    @machine = StateMachines::Machine.new(@klass, :action => :save)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    @result = @transition.perform
  end
  
  it 'should_have_empty_args' do
    assert_equal [], @transition.args
  end
  
  it 'should_have_a_result' do
    assert_equal 1, @transition.result
  end
  
  it 'should_be_successful' do
    assert_equal true, @result
  end
  
  it 'should_change_the_current_state' do
    assert_equal 'idling', @object.state
  end
  
  it 'should_run_the_action' do
    assert @object.saved
  end
  
  it 'should_run_the_action_after_saving_the_state' do
    assert_equal 'idling', @object.save_state
  end
end

context 'WithPerformArguments' do
  before(:each) do
    @klass = Class.new do
      attr_reader :saved
      
      def save
        @saved = true
      end
    end
    
    @machine = StateMachines::Machine.new(@klass, :action => :save)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_have_arguments' do
    @transition.perform(1, 2)
    
    assert_equal [1, 2], @transition.args
    assert @object.saved
  end
  
  it 'should_not_include_run_action_in_arguments' do
    @transition.perform(1, 2, false)
    
    assert_equal [1, 2], @transition.args
    assert !@object.saved
  end
end

context 'WithoutRunningAction' do
  before(:each) do
    @klass = Class.new do
      attr_reader :saved
      
      def save
        @saved = true
      end
    end
    
    @machine = StateMachines::Machine.new(@klass, :action => :save)
    @machine.state :parked, :idling
    @machine.event :ignite
    @machine.after_transition {|object| @run_after = true}
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    @result = @transition.perform(false)
  end
  
  it 'should_have_empty_args' do
    assert_equal [], @transition.args
  end
  
  it 'should_not_have_a_result' do
    assert_nil @transition.result
  end
  
  it 'should_be_successful' do
    assert_equal true, @result
  end
  
  it 'should_change_the_current_state' do
    assert_equal 'idling', @object.state
  end
  
  it 'should_not_run_the_action' do
    assert !@object.saved
  end
  
  it 'should_run_after_callbacks' do
    assert @run_after
  end
end

context 'WithTransactions' do
  before(:each) do
    @klass = Class.new do
      class << self
        attr_accessor :running_transaction
      end
      
      attr_accessor :result
      
      def save
        @result = self.class.running_transaction
        true
      end
    end
    
    @machine = StateMachines::Machine.new(@klass, :action => :save)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    
    class << @machine
      def within_transaction(object)
        owner_class.running_transaction = object
        yield
        owner_class.running_transaction = false
      end
    end
  end
  
  it 'should_run_blocks_within_transaction_for_object' do
    @transition.within_transaction do
      @result = @klass.running_transaction
    end
    
    assert_equal @object, @result
  end
end

context 'Transient' do
  before(:each) do
    @klass = Class.new
    
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    @transition.transient = true
  end
  
  it 'should_be_transient' do
    assert @transition.transient?
  end
end

context 'Equality' do
  before(:each) do
    @klass = Class.new
    
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    
    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
  
  it 'should_be_equal_with_same_properties' do
    transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    assert_equal transition, @transition
  end
  
  it 'should_not_be_equal_with_different_machines' do
    machine = StateMachines::Machine.new(@klass, :status, :namespace => :other)
    machine.state :parked, :idling
    machine.event :ignite
    transition = StateMachines::Transition.new(@object, machine, :ignite, :parked, :idling)
    
    assert_not_equal transition, @transition
  end
  
  it 'should_not_be_equal_with_different_objects' do
    transition = StateMachines::Transition.new(@klass.new, @machine, :ignite, :parked, :idling)
    assert_not_equal transition, @transition
  end
  
  it 'should_not_be_equal_with_different_event_names' do
    @machine.event :park
    transition = StateMachines::Transition.new(@object, @machine, :park, :parked, :idling)
    assert_not_equal transition, @transition
  end
  
  it 'should_not_be_equal_with_different_from_state_names' do
    @machine.state :first_gear
    transition = StateMachines::Transition.new(@object, @machine, :ignite, :first_gear, :idling)
    assert_not_equal transition, @transition
  end
  
  it 'should_not_be_equal_with_different_to_state_names' do
    @machine.state :first_gear
    transition = StateMachines::Transition.new(@object, @machine, :ignite, :idling, :first_gear)
    assert_not_equal transition, @transition
  end
end
