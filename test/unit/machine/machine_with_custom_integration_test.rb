require_relative '../../test_helper'
require_relative '../../../test/files/models/vehicle'

class MachineWithCustomIntegrationTest < StateMachinesTest
  def setup
    StateMachines::Integrations.reset
    integration = Module.new do
      include StateMachines::Integrations::Base

      def self.matching_ancestors
        ['Vehicle']
      end
    end

    StateMachines::Integrations.const_set('Custom', integration)
    StateMachines::Integrations.register(StateMachines::Integrations::Custom)

    @klass = Vehicle
  end

  def test_should_be_extended_by_the_integration_if_explicit
    machine = StateMachines::Machine.new(@klass, integration: :custom)
    assert((class << machine; ancestors; end).include?(StateMachines::Integrations::Custom))
  end

  def test_should_not_be_extended_by_the_integration_if_implicit_but_not_available
    StateMachines::Integrations::Custom.class_eval do
      class << self; remove_method :matching_ancestors; end
      def self.matching_ancestors
        []
      end
    end

    machine = StateMachines::Machine.new(@klass)
    assert(!(class << machine; ancestors; end).include?(StateMachines::Integrations::Custom))
  end

  def test_should_not_be_extended_by_the_integration_if_implicit_but_not_matched
    StateMachines::Integrations::Custom.class_eval do
      class << self; remove_method :matching_ancestors; end
      def self.matching_ancestors
        []
      end
    end

    machine = StateMachines::Machine.new(@klass)
    assert(!(class << machine; ancestors; end).include?(StateMachines::Integrations::Custom))
  end

  def test_should_be_extended_by_the_integration_if_implicit_and_available_and_matches
    machine = StateMachines::Machine.new(@klass)
    assert((class << machine; ancestors; end).include?(StateMachines::Integrations::Custom))
  end

  def test_should_not_be_extended_by_the_integration_if_nil
    machine = StateMachines::Machine.new(@klass, integration: nil)
    assert(!(class << machine; ancestors; end).include?(StateMachines::Integrations::Custom))
  end

  def test_should_not_be_extended_by_the_integration_if_false
    machine = StateMachines::Machine.new(@klass, integration: false)
    assert(!(class << machine; ancestors; end).include?(StateMachines::Integrations::Custom))
  end

  def teardown
    StateMachines::Integrations.reset
    StateMachines::Integrations.send(:remove_const, 'Custom')
  end
end
