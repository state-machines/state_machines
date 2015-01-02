require_relative '../../test_helper'

class MachineWithInitializeAndSuperTest < StateMachinesTest
  def setup
    @klass = Class.new do
      def initialize
        super()
      end
    end
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @object = @klass.new
  end

  def test_should_initialize_state
    assert_equal 'parked', @object.state
  end
end
