require 'spec_helper'

describe StateMachines::Event do
  context 'ByDefault' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)

      @object = @klass.new
    end

    it 'should_have_a_machine' do
      assert_equal @machine, @event.machine
    end

    it 'should_have_a_name' do
      assert_equal :ignite, @event.name
    end

    it 'should_have_a_qualified_name' do
      assert_equal :ignite, @event.qualified_name
    end

    it 'should_have_a_human_name' do
      assert_equal 'ignite', @event.human_name
    end

    it 'should_not_have_any_branches' do
      assert @event.branches.empty?
    end

    it 'should_have_no_known_states' do
      assert @event.known_states.empty?
    end

    it 'should_not_be_able_to_fire' do
      assert !@event.can_fire?(@object)
    end

    it 'should_not_have_a_transition' do
      assert_nil @event.transition_for(@object)
    end

    it 'should_define_a_predicate' do
      assert @object.respond_to?(:can_ignite?)
    end

    it 'should_define_a_transition_accessor' do
      assert @object.respond_to?(:ignite_transition)
    end

    it 'should_define_an_action' do
      assert @object.respond_to?(:ignite)
    end

    it 'should_define_a_bang_action' do
      assert @object.respond_to?(:ignite!)
    end
  end

  context '' do
    before(:each) do
      @machine = StateMachines::Machine.new(Class.new)
      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
      @event.transition :parked => :idling
    end

    it 'should_allow_changing_machine' do
      new_machine = StateMachines::Machine.new(Class.new)
      @event.machine = new_machine
      assert_equal new_machine, @event.machine
    end

    it 'should_allow_changing_human_name' do
      @event.human_name = 'Stop'
      assert_equal 'Stop', @event.human_name
    end

    it 'should_provide_matcher_helpers_during_initialization' do
      matchers = []

      @event.instance_eval do
        matchers = [all, any, same]
      end

      assert_equal [StateMachines::AllMatcher.instance, StateMachines::AllMatcher.instance, StateMachines::LoopbackMatcher.instance], matchers
    end

    it 'should_use_pretty_inspect' do
      assert_match "#<StateMachines::Event name=:ignite transitions=[:parked => :idling]>", @event.inspect
    end
  end

  context 'WithHumanName' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.events << @event = StateMachines::Event.new(@machine, :ignite, :human_name => 'start')
    end

    it 'should_use_custom_human_name' do
      assert_equal 'start', @event.human_name
    end
  end

  context 'WithDynamicHumanName' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.events << @event = StateMachines::Event.new(@machine, :ignite, :human_name => lambda { |event, object| ['start', object] })
    end

    it 'should_use_custom_human_name' do
      human_name, klass = @event.human_name
      assert_equal 'start', human_name
      assert_equal @klass, klass
    end

    it 'should_allow_custom_class_to_be_passed_through' do
      human_name, klass = @event.human_name(1)
      assert_equal 'start', human_name
      assert_equal 1, klass
    end

    it 'should_not_cache_value' do
      assert_not_same @event.human_name, @event.human_name
    end
  end

  context 'WithConflictingHelpersBeforeDefinition' do
    before(:each) do
      require 'stringio'
      @original_stderr, $stderr = $stderr, StringIO.new

      @superclass = Class.new do
        def can_ignite?
          0
        end

        def ignite_transition
          0
        end

        def ignite
          0
        end

        def ignite!
          0
        end
      end
      @klass = Class.new(@superclass)
      @machine = StateMachines::Machine.new(@klass)
      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
      @object = @klass.new
    end

    it 'should_not_redefine_predicate' do
      assert_equal 0, @object.can_ignite?
    end

    it 'should_not_redefine_transition_accessor' do
      assert_equal 0, @object.ignite_transition
    end

    it 'should_not_redefine_action' do
      assert_equal 0, @object.ignite
    end

    it 'should_not_redefine_bang_action' do
      assert_equal 0, @object.ignite!
    end

    it 'should_output_warning' do
      expected = %w(can_ignite? ignite_transition ignite ignite!).map do |method|
        "Instance method \"#{method}\" is already defined in #{@superclass.to_s}, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n"
      end.join

      assert_equal expected, $stderr.string
    end

    after(:each) do
      $stderr = @original_stderr
    end
  end

  context 'WithConflictingHelpersAfterDefinition' do
    before(:each) do
      require 'stringio'
      @original_stderr, $stderr = $stderr, StringIO.new

      @klass = Class.new do
        def can_ignite?
          0
        end

        def ignite_transition
          0
        end

        def ignite
          0
        end

        def ignite!
          0
        end
      end
      @machine = StateMachines::Machine.new(@klass)
      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
      @object = @klass.new
    end

    it 'should_not_redefine_predicate' do
      assert_equal 0, @object.can_ignite?
    end

    it 'should_not_redefine_transition_accessor' do
      assert_equal 0, @object.ignite_transition
    end

    it 'should_not_redefine_action' do
      assert_equal 0, @object.ignite
    end

    it 'should_not_redefine_bang_action' do
      assert_equal 0, @object.ignite!
    end

    it 'should_allow_super_chaining' do
      @klass.class_eval do
        def can_ignite?
          super
        end

        def ignite_transition
          super
        end

        def ignite
          super
        end

        def ignite!
          super
        end
      end

      assert_equal false, @object.can_ignite?
      assert_equal nil, @object.ignite_transition
      assert_equal false, @object.ignite
      assert_raise(StateMachines::InvalidTransition) { @object.ignite! }
    end

    it 'should_not_output_warning' do
      assert_equal '', $stderr.string
    end

    after(:each) do
      $stderr = @original_stderr
    end
  end

  context 'WithConflictingMachine' do
    before(:each) do
      require 'stringio'
      @original_stderr, $stderr = $stderr, StringIO.new

      @klass = Class.new
      @state_machine = StateMachines::Machine.new(@klass, :state)
      @state_machine.state :parked, :idling
      @state_machine.events << @state_event = StateMachines::Event.new(@state_machine, :ignite)
    end

    it 'should_not_overwrite_first_event' do
      @status_machine = StateMachines::Machine.new(@klass, :status)
      @status_machine.state :first_gear, :second_gear
      @status_machine.events << @status_event = StateMachines::Event.new(@status_machine, :ignite)

      @object = @klass.new
      @object.state = 'parked'
      @object.status = 'first_gear'

      @state_event.transition(:parked => :idling)
      @status_event.transition(:parked => :first_gear)

      @object.ignite
      assert_equal 'idling', @object.state
      assert_equal 'first_gear', @object.status
    end

    it 'should_output_warning' do
      @status_machine = StateMachines::Machine.new(@klass, :status)
      @status_machine.events << @status_event = StateMachines::Event.new(@status_machine, :ignite)

      assert_equal "Event :ignite for :status is already defined in :state\n", $stderr.string
    end

    it 'should_not_output_warning_if_using_different_namespace' do
      @status_machine = StateMachines::Machine.new(@klass, :status, :namespace => 'alarm')
      @status_machine.events << @status_event = StateMachines::Event.new(@status_machine, :ignite)

      assert_equal '', $stderr.string
    end

    after(:each) do
      $stderr = @original_stderr
    end
  end

  context 'WithNamespace' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass, :namespace => 'alarm')
      @machine.events << @event = StateMachines::Event.new(@machine, :enable)
      @object = @klass.new
    end

    it 'should_have_a_name' do
      assert_equal :enable, @event.name
    end

    it 'should_have_a_qualified_name' do
      assert_equal :enable_alarm, @event.qualified_name
    end

    it 'should_namespace_predicate' do
      assert @object.respond_to?(:can_enable_alarm?)
    end

    it 'should_namespace_transition_accessor' do
      assert @object.respond_to?(:enable_alarm_transition)
    end

    it 'should_namespace_action' do
      assert @object.respond_to?(:enable_alarm)
    end

    it 'should_namespace_bang_action' do
      assert @object.respond_to?(:enable_alarm!)
    end
  end

  context 'Context' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.events << @event = StateMachines::Event.new(@machine, :ignite, :human_name => 'start')
    end

    it 'should_evaluate_within_the_event' do
      scope = nil
      @event.context { scope = self }
      assert_equal @event, scope
    end
  end

  context 'Transitions' do
    before(:each) do
      @machine = StateMachines::Machine.new(Class.new)
      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
    end

    it 'should_not_raise_exception_if_implicit_option_specified' do
      assert_nothing_raised { @event.transition(:invalid => :valid) }
    end

    it 'should_not_allow_on_option' do
      assert_raise(ArgumentError) { @event.transition(:on => :ignite) }
    end

    it 'should_automatically_set_on_option' do
      branch = @event.transition(:to => :idling)
      assert_instance_of StateMachines::WhitelistMatcher, branch.event_requirement
      assert_equal [:ignite], branch.event_requirement.values
    end

    it 'should_not_allow_except_on_option' do
      assert_raise(ArgumentError) { @event.transition(:except_on => :ignite) }
    end

    it 'should_allow_transitioning_without_a_to_state' do
      assert_nothing_raised { @event.transition(:from => :parked) }
    end

    it 'should_allow_transitioning_without_a_from_state' do
      assert_nothing_raised { @event.transition(:to => :idling) }
    end

    it 'should_allow_except_from_option' do
      assert_nothing_raised { @event.transition(:except_from => :idling) }
    end

    it 'should_allow_except_to_option' do
      assert_nothing_raised { @event.transition(:except_to => :idling) }
    end

    it 'should_allow_transitioning_from_a_single_state' do
      assert @event.transition(:parked => :idling)
    end

    it 'should_allow_transitioning_from_multiple_states' do
      assert @event.transition([:parked, :idling] => :idling)
    end

    it 'should_allow_transitions_to_multiple_states' do
      assert @event.transition(:parked => [:parked, :idling])
    end

    it 'should_have_transitions' do
      branch = @event.transition(:to => :idling)
      assert_equal [branch], @event.branches
    end
  end

  context 'AfterBeingCopied' do
    before(:each) do
      @machine = StateMachines::Machine.new(Class.new)
      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
      @copied_event = @event.dup
    end

    it 'should_not_have_the_same_collection_of_branches' do
      assert_not_same @event.branches, @copied_event.branches
    end

    it 'should_not_have_the_same_collection_of_known_states' do
      assert_not_same @event.known_states, @copied_event.known_states
    end
  end

  context 'WithoutTransitions' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
      @object = @klass.new
    end

    it 'should_not_be_able_to_fire' do
      assert !@event.can_fire?(@object)
    end

    it 'should_not_have_a_transition' do
      assert_nil @event.transition_for(@object)
    end

    it 'should_not_fire' do
      assert !@event.fire(@object)
    end

    it 'should_not_change_the_current_state' do
      @event.fire(@object)
      assert_nil @object.state
    end
  end

  context 'WithTransitions' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
      @event.transition(:parked => :idling)
      @event.transition(:first_gear => :idling)
    end

    it 'should_include_all_transition_states_in_known_states' do
      assert_equal [:parked, :idling, :first_gear], @event.known_states
    end

    it 'should_include_new_transition_states_after_calling_known_states' do
      @event.known_states
      @event.transition(:stalled => :idling)

      assert_equal [:parked, :idling, :first_gear, :stalled], @event.known_states
    end

    it 'should_clear_known_states_on_reset' do
      @event.reset
      assert_equal [], @event.known_states
    end

    it 'should_use_pretty_inspect' do
      assert_match "#<StateMachines::Event name=:ignite transitions=[:parked => :idling, :first_gear => :idling]>", @event.inspect
    end
  end

  context 'WithoutMatchingTransitions' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling

      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
      @event.transition(:parked => :idling)

      @object = @klass.new
      @object.state = 'idling'
    end

    it 'should_not_be_able_to_fire' do
      assert !@event.can_fire?(@object)
    end

    it 'should_be_able_to_fire_with_custom_from_state' do
      assert @event.can_fire?(@object, :from => :parked)
    end

    it 'should_not_have_a_transition' do
      assert_nil @event.transition_for(@object)
    end

    it 'should_have_a_transition_with_custom_from_state' do
      assert_not_nil @event.transition_for(@object, :from => :parked)
    end

    it 'should_not_fire' do
      assert !@event.fire(@object)
    end

    it 'should_not_change_the_current_state' do
      @event.fire(@object)
      assert_equal 'idling', @object.state
    end
  end

  context 'WithMatchingDisabledTransitions' do
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
      end

      @machine = StateMachines::Machine.new(@klass, :integration => :custom)
      @machine.state :parked, :idling

      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
      @event.transition(:parked => :idling, :if => lambda { false })

      @object = @klass.new
      @object.state = 'parked'
    end

    it 'should_not_be_able_to_fire' do
      assert !@event.can_fire?(@object)
    end

    it 'should_be_able_to_fire_with_disabled_guards' do
      assert @event.can_fire?(@object, :guard => false)
    end

    it 'should_not_have_a_transition' do
      assert_nil @event.transition_for(@object)
    end

    it 'should_have_a_transition_with_disabled_guards' do
      assert_not_nil @event.transition_for(@object, :guard => false)
    end

    it 'should_not_fire' do
      assert !@event.fire(@object)
    end

    it 'should_not_change_the_current_state' do
      @event.fire(@object)
      assert_equal 'parked', @object.state
    end

    it 'should_invalidate_the_state' do
      @event.fire(@object)
      assert_equal ['cannot transition via "ignite"'], @object.errors
    end

    it 'should_invalidate_with_human_event_name' do
      @event.human_name = 'start'
      @event.fire(@object)
      assert_equal ['cannot transition via "start"'], @object.errors
    end

    it 'should_invalid_with_human_state_name_if_specified' do
      klass = Class.new do
        attr_accessor :errors
      end

      machine = StateMachines::Machine.new(klass, :integration => :custom, :messages => {:invalid_transition => 'cannot transition via "%s" from "%s"'})
      parked, idling = machine.state :parked, :idling
      parked.human_name = 'stopped'

      machine.events << event = StateMachines::Event.new(machine, :ignite)
      event.transition(:parked => :idling, :if => lambda { false })

      object = @klass.new
      object.state = 'parked'

      event.fire(object)
      assert_equal ['cannot transition via "ignite" from "stopped"'], object.errors
    end

    it 'should_reset_existing_error' do
      @object.errors = ['invalid']

      @event.fire(@object)
      assert_equal ['cannot transition via "ignite"'], @object.errors
    end

    it 'should_run_failure_callbacks' do
      callback_args = nil
      @machine.after_failure { |*args| callback_args = args }

      @event.fire(@object)

      object, transition = callback_args
      assert_equal @object, object
      assert_not_nil transition
      assert_equal @object, transition.object
      assert_equal @machine, transition.machine
      assert_equal :ignite, transition.event
      assert_equal :parked, transition.from_name
      assert_equal :parked, transition.to_name
    end

    after(:each) do
      StateMachines::Integrations.send(:remove_const, 'Custom')
      StateMachines::Integrations.send(:reset)
    end
  end

  context 'WithMatchingEnabledTransitions' do
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
      end

      @machine = StateMachines::Machine.new(@klass, :integration => :custom)
      @machine.state :parked, :idling

      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
      @event.transition(:parked => :idling)

      @object = @klass.new
      @object.state = 'parked'
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

    it 'should_fire' do
      assert @event.fire(@object)
    end

    it 'should_change_the_current_state' do
      @event.fire(@object)
      assert_equal 'idling', @object.state
    end

    it 'should_reset_existing_error' do
      @object.errors = ['invalid']

      @event.fire(@object)
      assert_equal [], @object.errors
    end

    it 'should_not_invalidate_the_state' do
      @event.fire(@object)
      assert_equal [], @object.errors
    end

    it 'should_not_be_able_to_fire_on_reset' do
      @event.reset
      assert !@event.can_fire?(@object)
    end

    after(:each) do
      StateMachines::Integrations.send(:remove_const, 'Custom')
      StateMachines::Integrations.send(:reset)
    end
  end

  context 'WithTransitionWithoutToState' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked

      @machine.events << @event = StateMachines::Event.new(@machine, :park)
      @event.transition(:from => :parked)

      @object = @klass.new
      @object.state = 'parked'
    end

    it 'should_be_able_to_fire' do
      assert @event.can_fire?(@object)
    end

    it 'should_have_a_transition' do
      transition = @event.transition_for(@object)
      assert_not_nil transition
      assert_equal 'parked', transition.from
      assert_equal 'parked', transition.to
      assert_equal :park, transition.event
    end

    it 'should_fire' do
      assert @event.fire(@object)
    end

    it 'should_not_change_the_current_state' do
      @event.fire(@object)
      assert_equal 'parked', @object.state
    end
  end

  context 'WithTransitionWithNilToState' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state nil, :idling

      @machine.events << @event = StateMachines::Event.new(@machine, :park)
      @event.transition(:idling => nil)

      @object = @klass.new
      @object.state = 'idling'
    end

    it 'should_be_able_to_fire' do
      assert @event.can_fire?(@object)
    end

    it 'should_have_a_transition' do
      transition = @event.transition_for(@object)
      assert_not_nil transition
      assert_equal 'idling', transition.from
      assert_equal nil, transition.to
      assert_equal :park, transition.event
    end

    it 'should_fire' do
      assert @event.fire(@object)
    end

    it 'should_not_change_the_current_state' do
      @event.fire(@object)
      assert_equal nil, @object.state
    end
  end

  context 'WithTransitionWithLoopbackState' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked

      @machine.events << @event = StateMachines::Event.new(@machine, :park)
      @event.transition(:from => :parked, :to => StateMachines::LoopbackMatcher.instance)

      @object = @klass.new
      @object.state = 'parked'
    end

    it 'should_be_able_to_fire' do
      assert @event.can_fire?(@object)
    end

    it 'should_have_a_transition' do
      transition = @event.transition_for(@object)
      assert_not_nil transition
      assert_equal 'parked', transition.from
      assert_equal 'parked', transition.to
      assert_equal :park, transition.event
    end

    it 'should_fire' do
      assert @event.fire(@object)
    end

    it 'should_not_change_the_current_state' do
      @event.fire(@object)
      assert_equal 'parked', @object.state
    end
  end

  context 'WithTransitionWithBlacklistedToState' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass, :initial => :parked)
      @machine.state :parked, :idling, :first_gear, :second_gear

      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
      @event.transition(:from => :parked, :to => StateMachines::BlacklistMatcher.new([:parked, :idling]))

      @object = @klass.new
      @object.state = 'parked'
    end

    it 'should_be_able_to_fire' do
      assert @event.can_fire?(@object)
    end

    it 'should_have_a_transition' do
      transition = @event.transition_for(@object)
      assert_not_nil transition
      assert_equal 'parked', transition.from
      assert_equal 'first_gear', transition.to
      assert_equal :ignite, transition.event
    end

    it 'should_allow_loopback_first_when_possible' do
      @event.transition(:from => :second_gear, :to => StateMachines::BlacklistMatcher.new([:parked, :idling]))
      @object.state = 'second_gear'

      transition = @event.transition_for(@object)
      assert_not_nil transition
      assert_equal 'second_gear', transition.from
      assert_equal 'second_gear', transition.to
      assert_equal :ignite, transition.event
    end

    it 'should_allow_specific_transition_selection_using_to' do
      transition = @event.transition_for(@object, :from => :parked, :to => :second_gear)

      assert_not_nil transition
      assert_equal 'parked', transition.from
      assert_equal 'second_gear', transition.to
      assert_equal :ignite, transition.event
    end

    it 'should_not_allow_transition_selection_if_not_matching' do
      transition = @event.transition_for(@object, :from => :parked, :to => :parked)
      assert_nil transition
    end

    it 'should_fire' do
      assert @event.fire(@object)
    end

    it 'should_change_the_current_state' do
      @event.fire(@object)
      assert_equal 'first_gear', @object.state
    end
  end

  context 'WithTransitionWithWhitelistedToState' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass, :initial => :parked)
      @machine.state :parked, :idling, :first_gear, :second_gear

      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
      @event.transition(:from => :parked, :to => StateMachines::WhitelistMatcher.new([:first_gear, :second_gear]))

      @object = @klass.new
      @object.state = 'parked'
    end

    it 'should_be_able_to_fire' do
      assert @event.can_fire?(@object)
    end

    it 'should_have_a_transition' do
      transition = @event.transition_for(@object)
      assert_not_nil transition
      assert_equal 'parked', transition.from
      assert_equal 'first_gear', transition.to
      assert_equal :ignite, transition.event
    end

    it 'should_allow_specific_transition_selection_using_to' do
      transition = @event.transition_for(@object, :from => :parked, :to => :second_gear)

      assert_not_nil transition
      assert_equal 'parked', transition.from
      assert_equal 'second_gear', transition.to
      assert_equal :ignite, transition.event
    end

    it 'should_not_allow_transition_selection_if_not_matching' do
      transition = @event.transition_for(@object, :from => :parked, :to => :parked)
      assert_nil transition
    end

    it 'should_fire' do
      assert @event.fire(@object)
    end

    it 'should_change_the_current_state' do
      @event.fire(@object)
      assert_equal 'first_gear', @object.state
    end
  end

  context 'WithMultipleTransitions' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling

      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
      @event.transition(:idling => :idling)
      @event.transition(:parked => :idling)
      @event.transition(:parked => :parked)

      @object = @klass.new
      @object.state = 'parked'
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

    it 'should_allow_specific_transition_selection_using_from' do
      transition = @event.transition_for(@object, :from => :idling)

      assert_not_nil transition
      assert_equal 'idling', transition.from
      assert_equal 'idling', transition.to
      assert_equal :ignite, transition.event
    end

    it 'should_allow_specific_transition_selection_using_to' do
      transition = @event.transition_for(@object, :from => :parked, :to => :parked)

      assert_not_nil transition
      assert_equal 'parked', transition.from
      assert_equal 'parked', transition.to
      assert_equal :ignite, transition.event
    end

    it 'should_not_allow_specific_transition_selection_using_on' do
      assert_raise(ArgumentError) { @event.transition_for(@object, :on => :park) }
    end

    it 'should_fire' do
      assert @event.fire(@object)
    end

    it 'should_change_the_current_state' do
      @event.fire(@object)
      assert_equal 'idling', @object.state
    end
  end

  context 'WithMachineAction' do
    before(:each) do
      @klass = Class.new do
        attr_reader :saved

        def save
          @saved = true
        end
      end

      @machine = StateMachines::Machine.new(@klass, :action => :save)
      @machine.state :parked, :idling

      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
      @event.transition(:parked => :idling)

      @object = @klass.new
      @object.state = 'parked'
    end

    it 'should_run_action_on_fire' do
      @event.fire(@object)
      assert @object.saved
    end

    it 'should_not_run_action_if_configured_to_skip' do
      @event.fire(@object, false)
      assert !@object.saved
    end
  end

  context 'WithInvalidCurrentState' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling

      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
      @event.transition(:parked => :idling)

      @object = @klass.new
      @object.state = 'invalid'
    end

    it 'should_raise_exception_when_checking_availability' do
      assert_raise(ArgumentError) { @event.can_fire?(@object) }
    end

    it 'should_raise_exception_when_finding_transition' do
      assert_raise(ArgumentError) { @event.transition_for(@object) }
    end

    it 'should_raise_exception_when_firing' do
      assert_raise(ArgumentError) { @event.fire(@object) }
    end
  end

  context 'OnFailure' do
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
      end

      @machine = StateMachines::Machine.new(@klass, :integration => :custom)
      @machine.state :parked
      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)

      @object = @klass.new
      @object.state = 'parked'
    end

    it 'should_invalidate_the_state' do
      @event.fire(@object)
      assert_equal ['cannot transition via "ignite"'], @object.errors
    end

    it 'should_run_failure_callbacks' do
      callback_args = nil
      @machine.after_failure { |*args| callback_args = args }

      @event.fire(@object)

      object, transition = callback_args
      assert_equal @object, object
      assert_not_nil transition
      assert_equal @object, transition.object
      assert_equal @machine, transition.machine
      assert_equal :ignite, transition.event
      assert_equal :parked, transition.from_name
      assert_equal :parked, transition.to_name
    end

    after(:each) do
      StateMachines::Integrations.send(:remove_const, 'Custom')
      StateMachines::Integrations.send(:reset)
    end
  end

  context 'WithMarshalling' do
    before(:each) do
      @klass = Class.new do
        def save
          true
        end
      end
      self.class.const_set('Example', @klass)

      @machine = StateMachines::Machine.new(@klass, :action => :save)
      @machine.state :parked, :idling

      @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
      @event.transition(:parked => :idling)

      @object = @klass.new
      @object.state = 'parked'
    end

    it 'should_marshal_during_before_callbacks' do
      @machine.before_transition { |object, transition| Marshal.dump(object) }
      assert_nothing_raised { @event.fire(@object) }
    end

    it 'should_marshal_during_action' do
      @klass.class_eval do
        remove_method :save

        def save
          Marshal.dump(self)
        end
      end

      assert_nothing_raised { @event.fire(@object) }
    end

    it 'should_marshal_during_after_callbacks' do
      @machine.after_transition { |object, transition| Marshal.dump(object) }
      assert_nothing_raised { @event.fire(@object) }
    end

    after(:each) do
      self.class.send(:remove_const, 'Example')
    end
  end
end