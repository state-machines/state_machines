require 'spec_helper'

describe StateMachines::EventCollection do
  context 'ByDefault' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @events = StateMachines::EventCollection.new(@machine)
      @object = @klass.new
    end

    it 'should_not_have_any_nodes' do
      assert_equal 0, @events.length
    end

    it 'should_have_a_machine' do
      assert_equal @machine, @events.machine
    end

    it 'should_not_have_any_valid_events_for_an_object' do
      assert @events.valid_for(@object).empty?
    end

    it 'should_not_have_any_transitions_for_an_object' do
      assert @events.transitions_for(@object).empty?
    end
  end

  context '' do
    before(:each) do
      machine = StateMachines::Machine.new(Class.new, :namespace => 'alarm')
      @events = StateMachines::EventCollection.new(machine)

      @events << @open = StateMachines::Event.new(machine, :enable)
      machine.events.concat(@events)
    end

    it 'should_index_by_name' do
      assert_equal @open, @events[:enable, :name]
    end

    it 'should_index_by_name_by_default' do
      assert_equal @open, @events[:enable]
    end

    it 'should_index_by_string_name' do
      assert_equal @open, @events['enable']
    end

    it 'should_index_by_qualified_name' do
      assert_equal @open, @events[:enable_alarm, :qualified_name]
    end

    it 'should_index_by_string_qualified_name' do
      assert_equal @open, @events['enable_alarm', :qualified_name]
    end
  end

  context 'EventStringCollection' do
    before(:each) do
      machine = StateMachines::Machine.new(Class.new, :namespace => 'alarm')
      @events = StateMachines::EventCollection.new(machine)

      @events << @open = StateMachines::Event.new(machine, 'enable')
      machine.events.concat(@events)
    end

    it 'should_index_by_name' do
      assert_equal @open, @events['enable', :name]
    end

    it 'should_index_by_name_by_default' do
      assert_equal @open, @events['enable']
    end

    it 'should_index_by_symbol_name' do
      assert_equal @open, @events[:enable]
    end

    it 'should_index_by_qualified_name' do
      assert_equal @open, @events['enable_alarm', :qualified_name]
    end

    it 'should_index_by_symbol_qualified_name' do
      assert_equal @open, @events[:enable_alarm, :qualified_name]
    end
  end

  context 'WithEventsWithTransitions' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass, :initial => :parked)
      @events = StateMachines::EventCollection.new(@machine)

      @machine.state :idling, :first_gear

      @events << @ignite = StateMachines::Event.new(@machine, :ignite)
      @ignite.transition :parked => :idling

      @events << @park = StateMachines::Event.new(@machine, :park)
      @park.transition :idling => :parked

      @events << @shift_up = StateMachines::Event.new(@machine, :shift_up)
      @shift_up.transition :parked => :first_gear
      @shift_up.transition :idling => :first_gear, :if => lambda { false }

      @machine.events.concat(@events)

      @object = @klass.new
    end

    it 'should_find_valid_events_based_on_current_state' do
      assert_equal [@ignite, @shift_up], @events.valid_for(@object)
    end

    it 'should_filter_valid_events_by_from_state' do
      assert_equal [@park], @events.valid_for(@object, :from => :idling)
    end

    it 'should_filter_valid_events_by_to_state' do
      assert_equal [@shift_up], @events.valid_for(@object, :to => :first_gear)
    end

    it 'should_filter_valid_events_by_event' do
      assert_equal [@ignite], @events.valid_for(@object, :on => :ignite)
    end

    it 'should_filter_valid_events_by_multiple_requirements' do
      assert_equal [], @events.valid_for(@object, :from => :idling, :to => :first_gear)
    end

    it 'should_allow_finding_valid_events_without_guards' do
      assert_equal [@shift_up], @events.valid_for(@object, :from => :idling, :to => :first_gear, :guard => false)
    end

    it 'should_find_valid_transitions_based_on_current_state' do
      assert_equal [
                       StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
                       StateMachines::Transition.new(@object, @machine, :shift_up, :parked, :first_gear)
                   ], @events.transitions_for(@object)
    end

    it 'should_filter_valid_transitions_by_from_state' do
      assert_equal [StateMachines::Transition.new(@object, @machine, :park, :idling, :parked)], @events.transitions_for(@object, :from => :idling)
    end

    it 'should_filter_valid_transitions_by_to_state' do
      assert_equal [StateMachines::Transition.new(@object, @machine, :shift_up, :parked, :first_gear)], @events.transitions_for(@object, :to => :first_gear)
    end

    it 'should_filter_valid_transitions_by_event' do
      assert_equal [StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)], @events.transitions_for(@object, :on => :ignite)
    end

    it 'should_filter_valid_transitions_by_multiple_requirements' do
      assert_equal [], @events.transitions_for(@object, :from => :idling, :to => :first_gear)
    end

    it 'should_allow_finding_valid_transitions_without_guards' do
      assert_equal [StateMachines::Transition.new(@object, @machine, :shift_up, :idling, :first_gear)], @events.transitions_for(@object, :from => :idling, :to => :first_gear, :guard => false)
    end
  end

  context 'WithMultipleEvents' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass, :initial => :parked)
      @events = StateMachines::EventCollection.new(@machine)

      @machine.state :first_gear
      @park, @shift_down = @machine.event :park, :shift_down

      @events << @park
      @park.transition :first_gear => :parked

      @events << @shift_down
      @shift_down.transition :first_gear => :parked

      @machine.events.concat(@events)
    end

    it 'should_only_include_all_valid_events_for_an_object' do
      object = @klass.new
      object.state = 'first_gear'
      assert_equal [@park, @shift_down], @events.valid_for(object)
    end
  end

  context 'WithoutMachineAction' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass, :initial => :parked)
      @events = StateMachines::EventCollection.new(@machine)
      @events << StateMachines::Event.new(@machine, :ignite)
      @machine.events.concat(@events)

      @object = @klass.new
    end

    it 'should_not_have_an_attribute_transition' do
      assert_nil @events.attribute_transition_for(@object)
    end
  end

  context 'AttributeWithMachineAction' do
    before(:each) do
      @klass = Class.new do
        def save
        end
      end

      @machine = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save)
      @events = StateMachines::EventCollection.new(@machine)

      @machine.state :parked, :idling
      @events << @ignite = StateMachines::Event.new(@machine, :ignite)
      @machine.events.concat(@events)

      @object = @klass.new
    end

    it 'should_not_have_transition_if_nil' do
      @object.state_event = nil
      assert_nil @events.attribute_transition_for(@object)
    end

    it 'should_not_have_transition_if_empty' do
      @object.state_event = ''
      assert_nil @events.attribute_transition_for(@object)
    end

    it 'should_have_invalid_transition_if_invalid_event_specified' do
      @object.state_event = 'invalid'
      assert_equal false, @events.attribute_transition_for(@object)
    end

    it 'should_have_invalid_transition_if_event_cannot_be_fired' do
      @object.state_event = 'ignite'
      assert_equal false, @events.attribute_transition_for(@object)
    end

    it 'should_have_valid_transition_if_event_can_be_fired' do
      @ignite.transition :parked => :idling
      @object.state_event = 'ignite'

      assert_instance_of StateMachines::Transition, @events.attribute_transition_for(@object)
    end

    it 'should_have_valid_transition_if_already_defined_in_transition_cache' do
      @ignite.transition :parked => :idling
      @object.state_event = nil
      @object.send(:state_event_transition=, transition = @ignite.transition_for(@object))

      assert_equal transition, @events.attribute_transition_for(@object)
    end

    it 'should_use_transition_cache_if_both_event_and_transition_are_present' do
      @ignite.transition :parked => :idling
      @object.state_event = 'ignite'
      @object.send(:state_event_transition=, transition = @ignite.transition_for(@object))

      assert_equal transition, @events.attribute_transition_for(@object)
    end
  end

  context 'AttributeWithNamespacedMachine' do
    before(:each) do
      @klass = Class.new do
        def save
        end
      end

      @machine = StateMachines::Machine.new(@klass, :namespace => 'alarm', :initial => :active, :action => :save)
      @events = StateMachines::EventCollection.new(@machine)

      @machine.state :active, :off
      @events << @disable = StateMachines::Event.new(@machine, :disable)
      @machine.events.concat(@events)

      @object = @klass.new
    end

    it 'should_not_have_transition_if_nil' do
      @object.state_event = nil
      assert_nil @events.attribute_transition_for(@object)
    end

    it 'should_have_invalid_transition_if_event_cannot_be_fired' do
      @object.state_event = 'disable'
      assert_equal false, @events.attribute_transition_for(@object)
    end

    it 'should_have_valid_transition_if_event_can_be_fired' do
      @disable.transition :active => :off
      @object.state_event = 'disable'

      assert_instance_of StateMachines::Transition, @events.attribute_transition_for(@object)
    end
  end

  context 'WithValidations' do
    before(:each) do
      StateMachines::Integrations.const_set('Custom', Module.new do
        include StateMachines::Integrations::Base

        def invalidate(object, attribute, message, values = [])
          (object.errors ||= []) << generate_message(message, values)
        end

        def reset(object)
          object.errors = []
        end
      end)

      @klass = Class.new do
        attr_accessor :errors

        def initialize
          @errors = []
          super
        end
      end

      @machine = StateMachines::Machine.new(@klass, :initial => :parked, :action => :save, :integration => :custom)
      @events = StateMachines::EventCollection.new(@machine)

      @parked, @idling = @machine.state :parked, :idling
      @events << @ignite = StateMachines::Event.new(@machine, :ignite)
      @machine.events.concat(@events)

      @object = @klass.new
    end

    it 'should_invalidate_if_invalid_event_specified' do
      @object.state_event = 'invalid'
      @events.attribute_transition_for(@object, true)

      assert_equal ['is invalid'], @object.errors
    end

    it 'should_invalidate_if_event_cannot_be_fired' do
      @object.state = 'idling'
      @object.state_event = 'ignite'
      @events.attribute_transition_for(@object, true)

      assert_equal ['cannot transition when idling'], @object.errors
    end

    it 'should_invalidate_with_human_name_if_invalid_event_specified' do
      @idling.human_name = 'waiting'
      @object.state = 'idling'
      @object.state_event = 'ignite'
      @events.attribute_transition_for(@object, true)

      assert_equal ['cannot transition when waiting'], @object.errors
    end

    it 'should_not_invalidate_event_can_be_fired' do
      @ignite.transition :parked => :idling
      @object.state_event = 'ignite'
      @events.attribute_transition_for(@object, true)

      assert_equal [], @object.errors
    end

    after(:each) do
      StateMachines::Integrations.send(:remove_const, 'Custom')
      StateMachines::Integrations.send(:reset)
    end
  end

  context 'WithCustomMachineAttribute' do
    before(:each) do
      @klass = Class.new do
        def save
        end
      end

      @machine = StateMachines::Machine.new(@klass, :state, :attribute => :state_id, :initial => :parked, :action => :save)
      @events = StateMachines::EventCollection.new(@machine)

      @machine.state :parked, :idling
      @events << @ignite = StateMachines::Event.new(@machine, :ignite)
      @machine.events.concat(@events)

      @object = @klass.new
    end

    it 'should_not_have_transition_if_nil' do
      @object.state_event = nil
      assert_nil @events.attribute_transition_for(@object)
    end

    it 'should_have_valid_transition_if_event_can_be_fired' do
      @ignite.transition :parked => :idling
      @object.state_event = 'ignite'

      assert_instance_of StateMachines::Transition, @events.attribute_transition_for(@object)
    end
  end
end