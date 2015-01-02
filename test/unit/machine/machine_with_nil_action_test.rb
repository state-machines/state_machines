require_relative '../../test_helper'

class MachineWithNilActionTest < StateMachinesTest
  def setup
    integration = Module.new do
      include StateMachines::Integrations::Base

      @defaults = { action: :save }
    end
    StateMachines::Integrations.const_set('Custom', integration)
    StateMachines::Integrations.register(StateMachines::Integrations::Custom)

    @machine = StateMachines::Machine.new(Class.new, action: nil, integration: :custom)
  end

  def test_should_have_a_nil_action
    assert_nil @machine.action
  end

  def teardown
    StateMachines::Integrations.reset
    StateMachines::Integrations.send(:remove_const, 'Custom')
  end
end
