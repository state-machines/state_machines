require 'spec_helper'

describe StateMachines::PathCollection do
  context 'ByDefault' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked

      @object = @klass.new
      @object.state = 'parked'

      @paths = StateMachines::PathCollection.new(@object, @machine)
    end

    it 'should_have_an_object' do
      assert_equal @object, @paths.object
    end

    it 'should_have_a_machine' do
      assert_equal @machine, @paths.machine
    end

    it 'should_have_a_from_name' do
      assert_equal :parked, @paths.from_name
    end

    it 'should_not_have_a_to_name' do
      assert_nil @paths.to_name
    end

    it 'should_have_no_from_states' do
      assert_equal [], @paths.from_states
    end

    it 'should_have_no_to_states' do
      assert_equal [], @paths.to_states
    end

    it 'should_have_no_events' do
      assert_equal [], @paths.events
    end

    it 'should_have_no_paths' do
      assert @paths.empty?
    end
  end

  context '' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @object = @klass.new
    end

    it 'should_raise_exception_if_invalid_option_specified' do
       assert_raise(ArgumentError) { StateMachines::PathCollection.new(@object, @machine, :invalid => true) }
      # FIXME
      # assert_equal 'Invalid key(s): invalid', exception.message
    end

    it 'should_raise_exception_if_invalid_from_state_specified' do
       assert_raise(IndexError) { StateMachines::PathCollection.new(@object, @machine, :from => :invalid) }
      # FIXME
      #assert_equal ':invalid is an invalid name', exception.message
    end

    it 'should_raise_exception_if_invalid_to_state_specified' do
      assert_raise(IndexError) { StateMachines::PathCollection.new(@object, @machine, :to => :invalid) }
      # FIXME
      #assert_equal ':invalid is an invalid name', exception.message
    end
  end

  context 'WithPaths' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling, :first_gear
      @machine.event :ignite do
        transition :parked => :idling
      end
      @machine.event :shift_up do
        transition :idling => :first_gear
      end

      @object = @klass.new
      @object.state = 'parked'

      @paths = StateMachines::PathCollection.new(@object, @machine)
    end

    it 'should_enumerate_paths' do
      assert_equal [[
                        StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
                        StateMachines::Transition.new(@object, @machine, :shift_up, :idling, :first_gear)
                    ]], @paths
    end

    it 'should_have_a_from_name' do
      assert_equal :parked, @paths.from_name
    end

    it 'should_not_have_a_to_name' do
      assert_nil @paths.to_name
    end

    it 'should_have_from_states' do
      assert_equal [:parked, :idling], @paths.from_states
    end

    it 'should_have_to_states' do
      assert_equal [:idling, :first_gear], @paths.to_states
    end

    it 'should_have_no_events' do
      assert_equal [:ignite, :shift_up], @paths.events
    end
  end

  context 'WithGuardedPaths' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling, :first_gear
      @machine.event :ignite do
        transition :parked => :idling, :if => lambda { false }
      end

      @object = @klass.new
      @object.state = 'parked'
    end

    it 'should_not_enumerate_paths_if_guard_enabled' do
      assert_equal [], StateMachines::PathCollection.new(@object, @machine)
    end

    it 'should_enumerate_paths_if_guard_disabled' do
      paths = StateMachines::PathCollection.new(@object, @machine, :guard => false)
      assert_equal [[
                        StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                    ]], paths
    end
  end

  context 'WithDuplicateNodes' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling
      @machine.event :shift_up do
        transition :parked => :idling, :idling => :first_gear
      end
      @machine.event :park do
        transition :first_gear => :idling
      end
      @object = @klass.new
      @object.state = 'parked'

      @paths = StateMachines::PathCollection.new(@object, @machine)
    end

    it 'should_not_include_duplicates_in_from_states' do
      assert_equal [:parked, :idling, :first_gear], @paths.from_states
    end

    it 'should_not_include_duplicates_in_to_states' do
      assert_equal [:idling, :first_gear], @paths.to_states
    end

    it 'should_not_include_duplicates_in_events' do
      assert_equal [:shift_up, :park], @paths.events
    end
  end

  context 'WithFromState' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling, :first_gear
      @machine.event :park do
        transition :idling => :parked
      end

      @object = @klass.new
      @object.state = 'parked'

      @paths = StateMachines::PathCollection.new(@object, @machine, :from => :idling)
    end

    it 'should_generate_paths_from_custom_from_state' do
      assert_equal [[
                        StateMachines::Transition.new(@object, @machine, :park, :idling, :parked)
                    ]], @paths
    end

    it 'should_have_a_from_name' do
      assert_equal :idling, @paths.from_name
    end
  end

  context 'WithToState' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling
      @machine.event :ignite do
        transition :parked => :idling
      end
      @machine.event :shift_up do
        transition :parked => :idling, :idling => :first_gear
      end
      @machine.event :shift_down do
        transition :first_gear => :idling
      end
      @object = @klass.new
      @object.state = 'parked'

      @paths = StateMachines::PathCollection.new(@object, @machine, :to => :idling)
    end

    it 'should_stop_paths_once_target_state_reached' do
      assert_equal [
                       [StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)],
                       [StateMachines::Transition.new(@object, @machine, :shift_up, :parked, :idling)]
                   ], @paths
    end
  end

  context 'WithDeepPaths' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling
      @machine.event :ignite do
        transition :parked => :idling
      end
      @machine.event :shift_up do
        transition :parked => :idling, :idling => :first_gear
      end
      @machine.event :shift_down do
        transition :first_gear => :idling
      end
      @object = @klass.new
      @object.state = 'parked'

      @paths = StateMachines::PathCollection.new(@object, @machine, :to => :idling, :deep => true)
    end

    it 'should_allow_target_to_be_reached_more_than_once_per_path' do
      assert_equal [
                       [
                           StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                       ],
                       [
                           StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
                           StateMachines::Transition.new(@object, @machine, :shift_up, :idling, :first_gear),
                           StateMachines::Transition.new(@object, @machine, :shift_down, :first_gear, :idling)
                       ],
                       [
                           StateMachines::Transition.new(@object, @machine, :shift_up, :parked, :idling)
                       ],
                       [
                           StateMachines::Transition.new(@object, @machine, :shift_up, :parked, :idling),
                           StateMachines::Transition.new(@object, @machine, :shift_up, :idling, :first_gear),
                           StateMachines::Transition.new(@object, @machine, :shift_down, :first_gear, :idling)
                       ]
                   ], @paths
    end
  end
end