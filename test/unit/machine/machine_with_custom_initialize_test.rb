require_relative '../../test_helper'

class MachineWithCustomInitializeTest < StateMachinesTest
  def setup
    @klass = Class.new do
      def initialize(state = nil, options = {})
        @state = state
        initialize_state_machines(options)
      end
    end
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @object = @klass.new
  end

  def test_should_initialize_state
    assert_equal 'parked', @object.state
  end

  def test_should_allow_custom_options
    @machine.state :idling
    @object = @klass.new('idling', static: :force)
    assert_equal 'parked', @object.state
  end
end
