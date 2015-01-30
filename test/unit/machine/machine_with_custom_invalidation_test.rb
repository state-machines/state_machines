require_relative '../../test_helper'

class MachineWithCustomInvalidationTest < StateMachinesTest
  module Custom
    include StateMachines::Integrations::Base

    def invalidate(object, _attribute, message, values = [])
      object.error = generate_message(message, values)
    end
  end

  def setup
    StateMachines::Integrations.register(MachineWithCustomInvalidationTest::Custom)

    @klass = Class.new do
      attr_accessor :error
    end

    @machine = StateMachines::Machine.new(@klass, integration: :custom, messages: {invalid_transition: 'cannot %s'})
    @machine.state :parked

    @object = @klass.new
    @object.state = 'parked'
  end

  def test_generate_custom_message
    assert_equal 'cannot park', @machine.generate_message(:invalid_transition, [[:event, :park]])
  end

  def test_use_custom_message
    @machine.invalidate(@object, :state, :invalid_transition, [[:event, 'park']])
    assert_equal 'cannot park', @object.error
  end

  def teardown
    StateMachines::Integrations.reset
  end
end

