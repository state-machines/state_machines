require 'spec_helper'

describe StateMachines::Path do
  context 'ByDefault' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @object = @klass.new

      @path = StateMachines::Path.new(@object, @machine)
    end

    it 'should_have_an_object' do
      assert_equal @object, @path.object
    end

    it 'should_have_a_machine' do
      assert_equal @machine, @path.machine
    end

    it 'should_not_have_walked_anywhere' do
      assert_equal [], @path
    end

    it 'should_not_have_a_from_name' do
      assert_nil @path.from_name
    end

    it 'should_have_no_from_states' do
      assert_equal [], @path.from_states
    end

    it 'should_not_have_a_to_name' do
      assert_nil @path.to_name
    end

    it 'should_have_no_to_states' do
      assert_equal [], @path.to_states
    end

    it 'should_have_no_events' do
      assert_equal [], @path.events
    end

    it 'should_not_be_able_to_walk_anywhere' do
      walked = false
      @path.walk { walked = true }
      assert_equal false, walked
    end

    it 'should_not_be_complete' do
      assert_equal false, @path.complete?
    end
  end

  context '' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @object = @klass.new
    end

    it 'should_raise_exception_if_invalid_option_specified' do
      assert_raise(ArgumentError) { StateMachines::Path.new(@object, @machine, :invalid => true) }
      # FIXME
      #assert_equal 'Invalid key(s): invalid', exception.message
    end
  end

  context 'WithoutTransitions' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling
      @machine.event :ignite

      @object = @klass.new

      @path = StateMachines::Path.new(@object, @machine)
      @path.concat([
                       @ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                   ])
    end

    it 'should_not_be_able_to_walk_anywhere' do
      walked = false
      @path.walk { walked = true }
      assert_equal false, walked
    end
  end

  context 'WithTransitions' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling, :first_gear
      @machine.event :ignite, :shift_up

      @object = @klass.new
      @object.state = 'parked'

      @path = StateMachines::Path.new(@object, @machine)
      @path.concat([
                       @ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
                       @shift_up_transition = StateMachines::Transition.new(@object, @machine, :shift_up, :idling, :first_gear)
                   ])
    end

    it 'should_enumerate_transitions' do
      assert_equal [@ignite_transition, @shift_up_transition], @path
    end

    it 'should_have_a_from_name' do
      assert_equal :parked, @path.from_name
    end

    it 'should_have_from_states' do
      assert_equal [:parked, :idling], @path.from_states
    end

    it 'should_have_a_to_name' do
      assert_equal :first_gear, @path.to_name
    end

    it 'should_have_to_states' do
      assert_equal [:idling, :first_gear], @path.to_states
    end

    it 'should_have_events' do
      assert_equal [:ignite, :shift_up], @path.events
    end

    it 'should_not_be_able_to_walk_anywhere' do
      walked = false
      @path.walk { walked = true }
      assert_equal false, walked
    end

    it 'should_be_complete' do
      assert_equal true, @path.complete?
    end
  end

  context 'WithDuplicates' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling
      @machine.event :park, :ignite

      @object = @klass.new
      @object.state = 'parked'

      @path = StateMachines::Path.new(@object, @machine)
      @path.concat([
                       @ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
                       @park_transition = StateMachines::Transition.new(@object, @machine, :park, :idling, :parked),
                       @ignite_again_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                   ])
    end

    it 'should_not_include_duplicates_in_from_states' do
      assert_equal [:parked, :idling], @path.from_states
    end

    it 'should_not_include_duplicates_in_to_states' do
      assert_equal [:idling, :parked], @path.to_states
    end

    it 'should_not_include_duplicates_in_events' do
      assert_equal [:ignite, :park], @path.events
    end
  end

  context 'WithAvailableTransitions' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling, :first_gear
      @machine.event :ignite
      @machine.event :shift_up do
        transition :idling => :first_gear
      end
      @machine.event :park do
        transition :idling => :parked
      end

      @object = @klass.new
      @object.state = 'parked'

      @path = StateMachines::Path.new(@object, @machine)
      @path.concat([
                       @ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                   ])
    end

    it 'should_not_be_complete' do
      assert !@path.complete?
    end

    it 'should_walk_each_available_transition' do
      paths = []
      @path.walk { |path| paths << path }

      assert_equal [
                       [@ignite_transition, StateMachines::Transition.new(@object, @machine, :shift_up, :idling, :first_gear)],
                       [@ignite_transition, StateMachines::Transition.new(@object, @machine, :park, :idling, :parked)]
                   ], paths
    end

    it 'should_yield_path_instances_when_walking' do
      @path.walk do |path|
        assert_instance_of StateMachines::Path, path
      end
    end

    it 'should_not_modify_current_path_after_walking' do
      @path.walk {}
      assert_equal [@ignite_transition], @path
    end

    it 'should_not_modify_object_after_walking' do
      @path.walk {}
      assert_equal 'parked', @object.state
    end
  end

  context 'WithGuardedTransitions' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling
      @machine.event :ignite
      @machine.event :shift_up do
        transition :idling => :first_gear, :if => lambda { false }
      end

      @object = @klass.new
      @object.state = 'parked'
    end

    it 'should_not_walk_transitions_if_guard_enabled' do
      path = StateMachines::Path.new(@object, @machine)
      path.concat([
                      StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                  ])

      paths = []
      path.walk { |next_path| paths << next_path }

      assert_equal [], paths
    end

    it 'should_not_walk_transitions_if_guard_disabled' do
      path = StateMachines::Path.new(@object, @machine, :guard => false)
      path.concat([
                      ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                  ])

      paths = []
      path.walk { |next_path| paths << next_path }

      assert_equal [
                       [ignite_transition, StateMachines::Transition.new(@object, @machine, :shift_up, :idling, :first_gear)]
                   ], paths
    end
  end

  context 'WithEncounteredTransitions' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling, :first_gear
      @machine.event :ignite do
        transition :parked => :idling
      end
      @machine.event :park do
        transition :idling => :parked
      end

      @object = @klass.new
      @object.state = 'parked'

      @path = StateMachines::Path.new(@object, @machine)
      @path.concat([
                       @ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
                       @park_transition = StateMachines::Transition.new(@object, @machine, :park, :idling, :parked)
                   ])
    end

    it 'should_be_complete' do
      assert_equal true, @path.complete?
    end

    it 'should_not_be_able_to_walk' do
      walked = false
      @path.walk { walked = true }
      assert_equal false, walked
    end
  end

  context 'WithUnreachedTarget' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling
      @machine.event :ignite do
        transition :parked => :idling
      end

      @object = @klass.new
      @object.state = 'parked'

      @path = StateMachines::Path.new(@object, @machine, :target => :parked)
      @path.concat([
                       @ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                   ])
    end

    it 'should_not_be_complete' do
      assert_equal false, @path.complete?
    end

    it 'should_not_be_able_to_walk' do
      walked = false
      @path.walk { walked = true }
      assert_equal false, walked
    end
  end

  context 'WithReachedTarget' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling
      @machine.event :ignite do
        transition :parked => :idling
      end
      @machine.event :park do
        transition :idling => :parked
      end

      @object = @klass.new
      @object.state = 'parked'

      @path = StateMachines::Path.new(@object, @machine, :target => :parked)
      @path.concat([
                       @ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
                       @park_transition = StateMachines::Transition.new(@object, @machine, :park, :idling, :parked)
                   ])
    end

    it 'should_be_complete' do
      assert_equal true, @path.complete?
    end

    it 'should_not_be_able_to_walk' do
      walked = false
      @path.walk { walked = true }
      assert_equal false, walked
    end
  end

  context 'WithAvailableTransitionsAfterReachingTarget' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling
      @machine.event :ignite do
        transition :parked => :idling
      end
      @machine.event :shift_up do
        transition :parked => :first_gear
      end
      @machine.event :park do
        transition [:idling, :first_gear] => :parked
      end

      @object = @klass.new
      @object.state = 'parked'

      @path = StateMachines::Path.new(@object, @machine, :target => :parked)
      @path.concat([
                       @ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
                       @park_transition = StateMachines::Transition.new(@object, @machine, :park, :idling, :parked)
                   ])
    end

    it 'should_be_complete' do
      assert_equal true, @path.complete?
    end

    it 'should_be_able_to_walk' do
      paths = []
      @path.walk { |path| paths << path }
      assert_equal [
                       [@ignite_transition, @park_transition, StateMachines::Transition.new(@object, @machine, :shift_up, :parked, :first_gear)]
                   ], paths
    end
  end

  context 'WithDeepTarget' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling
      @machine.event :ignite do
        transition :parked => :idling
      end
      @machine.event :shift_up do
        transition :parked => :first_gear
      end
      @machine.event :park do
        transition [:idling, :first_gear] => :parked
      end

      @object = @klass.new
      @object.state = 'parked'

      @path = StateMachines::Path.new(@object, @machine, :target => :parked)
      @path.concat([
                       @ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
                       @park_transition = StateMachines::Transition.new(@object, @machine, :park, :idling, :parked),
                       @shift_up_transition = StateMachines::Transition.new(@object, @machine, :shift_up, :parked, :first_gear)
                   ])
    end

    it 'should_not_be_complete' do
      assert_equal false, @path.complete?
    end

    it 'should_be_able_to_walk' do
      paths = []
      @path.walk { |path| paths << path }
      assert_equal [
                       [@ignite_transition, @park_transition, @shift_up_transition, StateMachines::Transition.new(@object, @machine, :park, :first_gear, :parked)]
                   ], paths
    end
  end

  context 'WithDeepTargetReached' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling
      @machine.event :ignite do
        transition :parked => :idling
      end
      @machine.event :shift_up do
        transition :parked => :first_gear
      end
      @machine.event :park do
        transition [:idling, :first_gear] => :parked
      end

      @object = @klass.new
      @object.state = 'parked'

      @path = StateMachines::Path.new(@object, @machine, :target => :parked)
      @path.concat([
                       @ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
                       @park_transition = StateMachines::Transition.new(@object, @machine, :park, :idling, :parked),
                       @shift_up_transition = StateMachines::Transition.new(@object, @machine, :shift_up, :parked, :first_gear),
                       @park_transition_2 = StateMachines::Transition.new(@object, @machine, :park, :first_gear, :parked)
                   ])
    end

    it 'should_be_complete' do
      assert_equal true, @path.complete?
    end

    it 'should_not_be_able_to_walk' do
      walked = false
      @path.walk { walked = true }
      assert_equal false, walked
    end

    it 'should_not_be_able_to_walk_with_available_transitions' do
      @machine.event :park do
        transition :parked => same
      end

      walked = false
      @path.walk { walked = true }
      assert_equal false, walked
    end
  end
end