require_relative '../../test_helper'

class MachineWithInitialStateWithValueAndOwnerDefault < StateMachinesTest
  def setup
    @original_stderr, $stderr = $stderr, StringIO.new

    state_machine_with_defaults = Class.new(StateMachines::Machine) do
      def owner_class_attribute_default
        0
      end
    end
    @klass = Class.new
    @machine = state_machine_with_defaults.new(@klass, initial: :parked) do
      state :parked, value: 0
    end
  end

  def test_should_not_warn_about_wrong_default
    assert_equal '', $stderr.string
  end

  def teardown
    $stderr = @original_stderr
  end
end
