require_relative '../../test_helper'

class Validateable
  class << self
    def validate(*args, &block)
      args << block if block_given?
      args
    end
  end
end

class StateContextTest < StateMachinesTest
  def setup
    @klass = Class.new(Validateable)
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @state = @machine.state :parked

    @state_context = StateMachines::StateContext.new(@state)
  end

  def test_should_have_a_machine
    assert_equal @machine, @state_context.machine
  end

  def test_should_have_a_state
    assert_equal @state, @state_context.state
  end
end
