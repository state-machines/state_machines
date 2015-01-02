require_relative '../../test_helper'

class InvalidTransitionWithIntegrationTest < StateMachinesTest
  def setup
    StateMachines::Integrations.const_set('Custom', Module.new do
                                                    include StateMachines::Integrations::Base

                                                    def errors_for(object)
                                                      object.errors
                                                    end
                                                  end)

    StateMachines::Integrations.register(StateMachines::Integrations::Custom)


    @klass = Class.new do
      attr_accessor :errors
    end
    @machine = StateMachines::Machine.new(@klass, integration: :custom)
    @machine.state :parked
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
  end

  def fix_test
    skip
  end

  def test_should_generate_a_message_without_reasons_if_empty
    @object.errors = ''
    invalid_transition = StateMachines::InvalidTransition.new(@object, @machine, :ignite)
    assert_equal 'Cannot transition state via :ignite from :parked', invalid_transition.message
  end

  def test_should_generate_a_message_with_error_reasons_if_errors_found
    @object.errors = 'Id is invalid, Name is invalid'
    invalid_transition = StateMachines::InvalidTransition.new(@object, @machine, :ignite)
    assert_equal 'Cannot transition state via :ignite from :parked (Reason(s): Id is invalid, Name is invalid)', invalid_transition.message
  end

  def teardown
    StateMachines::Integrations.reset
    StateMachines::Integrations.send(:remove_const, 'Custom')
  end
end
