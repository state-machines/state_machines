require_relative '../../test_helper'

class MachineWithStateWithMatchersTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @state = @machine.state :parked, if: ->(value) {!value.nil? }

    @object = @klass.new
    @object.state = 1
  end

  def test_should_use_custom_matcher
    refute_nil @state.matcher
    assert @state.matches?(1)
    refute @state.matches?(nil)
  end
end

