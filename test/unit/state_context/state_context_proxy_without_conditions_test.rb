require_relative '../../test_helper'

class StateContextProxyWithoutConditionsTest < StateMachinesTest
  def setup
    @klass = Class.new(Validateable)
    machine = StateMachines::Machine.new(@klass, initial: :parked)
    state = machine.state :parked

    @state_context = StateMachines::StateContext.new(state)
    @object = @klass.new

    @options = @state_context.validate[0]
  end

  def test_should_have_options_configuration
    assert_instance_of Hash, @options
  end

  def test_should_have_if_option
    refute_nil @options[:if]
  end

  def test_should_be_false_if_state_is_different
    @object.state = nil
    refute @options[:if].call(@object)
  end

  def test_should_be_true_if_state_matches
    assert @options[:if].call(@object)
  end
end
