require_relative '../../test_helper'

class StateContextProxyTest < StateMachinesTest
  def setup
    @klass = Class.new(Validateable)
    machine = StateMachines::Machine.new(@klass, initial: :parked)
    state = machine.state :parked

    @state_context = StateMachines::StateContext.new(state)
  end

  def test_should_call_class_with_same_arguments
    options = {}
    validation = @state_context.validate(:name, options)

    assert_equal [:name, options], validation
  end

  def test_should_pass_block_through_to_class
    options = {}
    proxy_block = lambda {}
    validation = @state_context.validate(:name, options, &proxy_block)

    assert_equal [:name, options, proxy_block], validation
  end
end
