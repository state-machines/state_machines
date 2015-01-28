require_relative '../../test_helper'

class MachineWithStaticInitialStateTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
  end

  def test_should_not_have_dynamic_initial_state
    refute @machine.dynamic_initial_state?
  end

  def test_should_have_an_initial_state
    object = @klass.new
    assert_equal 'parked', @machine.initial_state(object).value
  end

  def test_should_write_to_attribute_when_initializing_state
    object = @klass.allocate
    @machine.initialize_state(object)
    assert_equal 'parked', object.state
  end

  def test_should_set_initial_on_state_object
    assert @machine.state(:parked).initial
  end

  def test_should_set_initial_state_on_created_object
    assert_equal 'parked', @klass.new.state
  end

  def test_should_not_initial_state_prior_to_initialization
    base = Class.new do
      attr_accessor :state_on_init

      def initialize
        self.state_on_init = state
      end
    end
    klass = Class.new(base)
    StateMachines::Machine.new(klass, initial: :parked)

    assert_nil klass.new.state_on_init
  end

  def test_should_be_included_in_known_states
    assert_equal [:parked], @machine.states.keys
  end
end
