# frozen_string_literal: true

require 'test_helper'

class IntegrationOptionsTest < StateMachinesTest
  def test_should_have_empty_integration_options_by_default
    integration = Class.new do
      include StateMachines::Integrations::Base
    end

    assert_empty integration.integration_options
  end

  def test_should_allow_integration_to_define_custom_options
    integration = Class.new do
      include StateMachines::Integrations::Base

      def self.integration_options
        %i[custom_option another_option]
      end
    end

    assert_equal %i[custom_option another_option], integration.integration_options
  end

  def test_should_accept_integration_specific_options_in_state_machine
    # Create a test integration
    integration = Module.new do
      include StateMachines::Integrations::Base

      def self.integration_options
        [:test_option]
      end

      def self.matching_ancestors
        [TestModel]
      end
    end

    # Register the integration
    StateMachines::Integrations.register(integration)

    # Create a test model
    model = Class.new do
      def self.name
        'TestModel'
      end
    end
    Object.const_set('TestModel', model)

    # Should not raise error with integration-specific option
    machine = model.state_machine test_option: true do
      state :active
    end

    # Verify the machine was created successfully
    assert_instance_of StateMachines::Machine, machine
    assert_equal :state, machine.name
    assert_includes machine.states.map(&:name), :active
  ensure
    # Clean up
    StateMachines::Integrations.send(:integrations).delete(integration)
    Object.send(:remove_const, 'TestModel') if defined?(TestModel)
  end

  def test_should_reject_unknown_options
    model = Class.new

    error = assert_raises(ArgumentError) do
      model.state_machine unknown_option: true do
        state :active
      end
    end

    assert_match(/Unknown key: :unknown_option/, error.message)
  end
end
