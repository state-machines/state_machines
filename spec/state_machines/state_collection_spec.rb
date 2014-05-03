require 'spec_helper'

context 'ByDefault' do
  before(:each) do
    @machine = StateMachines::Machine.new(Class.new)
    @states = StateMachines::StateCollection.new(@machine)
  end

  it 'should_not_have_any_nodes' do
    assert_equal 0, @states.length
  end

  it 'should_have_a_machine' do
    assert_equal @machine, @states.machine
  end

  it 'should_be_empty_by_priority' do
    assert_equal [], @states.by_priority
  end
end

context '' do
  before(:each) do
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @states = StateMachines::StateCollection.new(@machine)

    @states << @nil = StateMachines::State.new(@machine, nil)
    @states << @parked = StateMachines::State.new(@machine, :parked)
    @states << @idling = StateMachines::State.new(@machine, :idling)
    @machine.states.concat(@states)

    @object = @klass.new
  end

  it 'should_index_by_name' do
    assert_equal @parked, @states[:parked, :name]
  end

  it 'should_index_by_name_by_default' do
    assert_equal @parked, @states[:parked]
  end

  it 'should_index_by_string_name' do
    assert_equal @parked, @states['parked']
  end

  it 'should_index_by_qualified_name' do
    assert_equal @parked, @states[:parked, :qualified_name]
  end

  it 'should_index_by_string_qualified_name' do
    assert_equal @parked, @states['parked', :qualified_name]
  end

  it 'should_index_by_value' do
    assert_equal @parked, @states['parked', :value]
  end

  it 'should_not_match_if_value_does_not_match' do
    assert !@states.matches?(@object, :parked)
    assert !@states.matches?(@object, :idling)
  end

  it 'should_match_if_value_matches' do
    assert @states.matches?(@object, nil)
  end

  it 'raise_exception_if_matching_invalid_state' do
    assert_raise(IndexError) { @states.matches?(@object, :invalid) }
  end

  it 'should_find_state_for_object_if_value_is_known' do
    @object.state = 'parked'
    assert_equal @parked, @states.match(@object)
  end

  it 'should_find_bang_state_for_object_if_value_is_known' do
    @object.state = 'parked'
    assert_equal @parked, @states.match!(@object)
  end

  it 'should_not_find_state_for_object_with_unknown_value' do
    @object.state = 'invalid'
    assert_nil @states.match(@object)
  end

  it 'should_raise_exception_if_finding_bang_state_for_object_with_unknown_value' do
    @object.state = 'invalid'
    assert_raise(ArgumentError) { @states.match!(@object) }
    #assert_equal '"invalid" is not a known state value', exception.message
  end
end

context 'String' do
  before(:each) do
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @states = StateMachines::StateCollection.new(@machine)

    @states << @nil = StateMachines::State.new(@machine, nil)
    @states << @parked = StateMachines::State.new(@machine, 'parked')
    @machine.states.concat(@states)

    @object = @klass.new
  end

  it 'should_index_by_name' do
    assert_equal @parked, @states['parked', :name]
  end

  it 'should_index_by_name_by_default' do
    assert_equal @parked, @states['parked']
  end

  it 'should_index_by_symbol_name' do
    assert_equal @parked, @states[:parked]
  end

  it 'should_index_by_qualified_name' do
    assert_equal @parked, @states['parked', :qualified_name]
  end

  it 'should_index_by_symbol_qualified_name' do
    assert_equal @parked, @states[:parked, :qualified_name]
  end
end

context 'WithNamespace' do
  before(:each) do
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, :namespace => 'vehicle')
    @states = StateMachines::StateCollection.new(@machine)

    @states << @state = StateMachines::State.new(@machine, :parked)
    @machine.states.concat(@states)
  end

  it 'should_index_by_name' do
    assert_equal @state, @states[:parked, :name]
  end

  it 'should_index_by_qualified_name' do
    assert_equal @state, @states[:vehicle_parked, :qualified_name]
  end
end

context 'WithCustomStateValues' do
  before(:each) do
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @states = StateMachines::StateCollection.new(@machine)

    @states << @state = StateMachines::State.new(@machine, :parked, :value => 1)
    @machine.states.concat(@states)

    @object = @klass.new
    @object.state = 1
  end

  it 'should_match_if_value_matches' do
    assert @states.matches?(@object, :parked)
  end

  it 'should_not_match_if_value_does_not_match' do
    @object.state = 2
    assert !@states.matches?(@object, :parked)
  end

  it 'should_find_state_for_object_if_value_is_known' do
    assert_equal @state, @states.match(@object)
  end
end

context 'WithStateMatchers' do
  before(:each) do
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @states = StateMachines::StateCollection.new(@machine)

    @states << @state = StateMachines::State.new(@machine, :parked, :if => lambda {|value| !value.nil?})
    @machine.states.concat(@states)

    @object = @klass.new
    @object.state = 1
  end

  it 'should_match_if_value_matches' do
    assert @states.matches?(@object, :parked)
  end

  it 'should_not_match_if_value_does_not_match' do
    @object.state = nil
    assert !@states.matches?(@object, :parked)
  end

  it 'should_find_state_for_object_if_value_is_known' do
    assert_equal @state, @states.match(@object)
  end
end

context 'WithInitialState' do
  before(:each) do
    @machine = StateMachines::Machine.new(Class.new)
    @states = StateMachines::StateCollection.new(@machine)

    @states << @parked = StateMachines::State.new(@machine, :parked)
    @states << @idling = StateMachines::State.new(@machine, :idling)
    @machine.states.concat(@states)

    @parked.initial = true
  end

  it 'should_order_state_before_transition_states' do
    @machine.event :ignite do
      transition :to => :idling
    end
    assert_equal [@parked, @idling], @states.by_priority
  end

  it 'should_order_state_before_states_with_behaviors' do
    @idling.context do
      def speed
        0
      end
    end
    assert_equal [@parked, @idling], @states.by_priority
  end

  it 'should_order_state_before_other_states' do
    assert_equal [@parked, @idling], @states.by_priority
  end

  it 'should_order_state_before_callback_states' do
    @machine.before_transition :from => :idling, :do => lambda {}
    assert_equal [@parked, @idling], @states.by_priority
  end
end

context 'WithStateBehaviors' do
  before(:each) do
    @machine = StateMachines::Machine.new(Class.new)
    @states = StateMachines::StateCollection.new(@machine)

    @states << @parked = StateMachines::State.new(@machine, :parked)
    @states << @idling = StateMachines::State.new(@machine, :idling)
    @machine.states.concat(@states)

    @idling.context do
      def speed
        0
      end
    end
  end

  it 'should_order_states_after_initial_state' do
    @parked.initial = true
    assert_equal [@parked, @idling], @states.by_priority
  end

  it 'should_order_states_after_transition_states' do
    @machine.event :ignite do
      transition :from => :parked
    end
    assert_equal [@parked, @idling], @states.by_priority
  end

  it 'should_order_states_before_other_states' do
    assert_equal [@idling, @parked], @states.by_priority
  end

  it 'should_order_state_before_callback_states' do
    @machine.before_transition :from => :parked, :do => lambda {}
    assert_equal [@idling, @parked], @states.by_priority
  end
end

context 'WithEventTransitions' do
  before(:each) do
    @machine = StateMachines::Machine.new(Class.new)
    @states = StateMachines::StateCollection.new(@machine)

    @states << @parked = StateMachines::State.new(@machine, :parked)
    @states << @idling = StateMachines::State.new(@machine, :idling)
    @machine.states.concat(@states)

    @machine.event :ignite do
      transition :to => :idling
    end
  end

  it 'should_order_states_after_initial_state' do
    @parked.initial = true
    assert_equal [@parked, @idling], @states.by_priority
  end

  it 'should_order_states_before_states_with_behaviors' do
    @parked.context do
      def speed
        0
      end
    end
    assert_equal [@idling, @parked], @states.by_priority
  end

  it 'should_order_states_before_other_states' do
    assert_equal [@idling, @parked], @states.by_priority
  end

  it 'should_order_state_before_callback_states' do
    @machine.before_transition :from => :parked, :do => lambda {}
    assert_equal [@idling, @parked], @states.by_priority
  end
end

context 'WithTransitionCallbacks' do
  before(:each) do
    @machine = StateMachines::Machine.new(Class.new)
    @states = StateMachines::StateCollection.new(@machine)
    
    @states << @parked = StateMachines::State.new(@machine, :parked)
    @states << @idling = StateMachines::State.new(@machine, :idling)
    @machine.states.concat(@states)
    
    @machine.before_transition :to => :idling, :do => lambda {}
  end
  
  it 'should_order_states_after_initial_state' do
    @parked.initial = true
    assert_equal [@parked, @idling], @states.by_priority
  end
  
  it 'should_order_states_after_transition_states' do
    @machine.event :ignite do
      transition :from => :parked
    end
    assert_equal [@parked, @idling], @states.by_priority
  end
  
  it 'should_order_states_after_states_with_behaviors' do
    @parked.context do
      def speed
        0
      end
    end
    assert_equal [@parked, @idling], @states.by_priority
  end
  
  it 'should_order_states_after_other_states' do
    assert_equal [@parked, @idling], @states.by_priority
  end
end
