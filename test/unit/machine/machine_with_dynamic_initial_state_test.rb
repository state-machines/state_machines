require_relative '../../test_helper'

class MachineWithDynamicInitialStateTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_accessor :initial_state
    end
    @machine = StateMachines::Machine.new(@klass, initial: lambda { |object| object.initial_state || :default })
    @machine.state :parked, :idling, :default
    @object = @klass.new
  end

  def test_should_have_dynamic_initial_state
    assert @machine.dynamic_initial_state?
  end

  def test_should_use_the_record_for_determining_the_initial_state
    @object.initial_state = :parked
    assert_equal :parked, @machine.initial_state(@object).name

    @object.initial_state = :idling
    assert_equal :idling, @machine.initial_state(@object).name
  end

  def test_should_write_to_attribute_when_initializing_state
    object = @klass.allocate
    object.initial_state = :parked
    @machine.initialize_state(object)
    assert_equal 'parked', object.state
  end

  def test_should_set_initial_state_on_created_object
    assert_equal 'default', @object.state
  end

  def test_should_not_set_initial_state_even_if_not_empty
    @klass.class_eval do
      def initialize(_attributes = {})
        self.state = 'parked'
        super()
      end
    end
    object = @klass.new
    assert_equal 'parked', object.state
  end

  def test_should_set_initial_state_after_initialization
    base = Class.new do
      attr_accessor :state_on_init

      def initialize
        self.state_on_init = state
      end
    end
    klass = Class.new(base)
    machine = StateMachines::Machine.new(klass, initial: lambda { |_object| :parked })
    machine.state :parked

    assert_nil klass.new.state_on_init
  end

  def test_should_not_be_included_in_known_states
    assert_equal [:parked, :idling, :default], @machine.states.map { |state| state.name }
  end
end
