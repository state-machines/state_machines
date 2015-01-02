require_relative '../../test_helper'

class MachineWithInitializeWithoutSuperTest < StateMachinesTest
  def setup
    @klass = Class.new do
      def initialize
      end
    end
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @object = @klass.new
  end

  def test_should_not_initialize_state
    assert_nil @object.state
  end
end

