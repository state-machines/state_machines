require_relative '../../test_helper'

class MachineWithoutInitializeTest < StateMachinesTest
  def setup
    klass = Class.new
    StateMachines::Machine.new(klass, initial: :parked)
    @object = klass.new
  end

  def test_should_initialize_state
    assert_equal 'parked', @object.state
  end
end

