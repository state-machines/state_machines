require_relative '../../test_helper'

class MachineWithNilActionTest < StateMachinesTest
  module Custom
    include StateMachines::Integrations::Base

    @defaults = {action: :save}
  end

  def setup
    StateMachines::Integrations.register(MachineWithNilActionTest::Custom)
  end

  def test_should_have_a_nil_action
    machine = StateMachines::Machine.new(Class.new, action: nil, integration: :custom)
    assert_nil machine.action
  end

  def test_should_have_default_action
    machine = StateMachines::Machine.new(Class.new, integration: :custom)
    assert_equal :save,  machine.action
  end

  def teardown
    StateMachines::Integrations.reset
  end
end
