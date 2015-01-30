require_relative '../../test_helper'
require_relative '../../../test/files/models/vehicle'

class MachineWithCustomIntegrationTest < StateMachinesTest
  module Custom
    include StateMachines::Integrations::Base

    def self.matching_ancestors
      ['Vehicle']
    end
  end

  def setup
    StateMachines::Integrations.register(MachineWithCustomIntegrationTest::Custom)

    @klass = Vehicle
  end

  def test_should_be_extended_by_the_integration_if_explicit
    machine = StateMachines::Machine.new(@klass, integration: :custom)
    assert((class << machine; ancestors; end).include?(MachineWithCustomIntegrationTest::Custom))
  end

  def test_should_not_be_extended_by_the_integration_if_implicit_but_not_available
    MachineWithCustomIntegrationTest::Custom.class_eval do
      class << self; remove_method :matching_ancestors; end
      def self.matching_ancestors
        []
      end
    end

    machine = StateMachines::Machine.new(@klass)
    assert(!(class << machine; ancestors; end).include?(MachineWithCustomIntegrationTest::Custom))
  end

  def test_should_not_be_extended_by_the_integration_if_implicit_but_not_matched
    MachineWithCustomIntegrationTest::Custom.class_eval do
      class << self; remove_method :matching_ancestors; end
      def self.matching_ancestors
        []
      end
    end

    machine = StateMachines::Machine.new(@klass)
    assert(!(class << machine; ancestors; end).include?(MachineWithCustomIntegrationTest::Custom))
  end

  def test_should_be_extended_by_the_integration_if_implicit_and_available_and_matches
    machine = StateMachines::Machine.new(@klass)
    assert((class << machine; ancestors; end).include?(MachineWithCustomIntegrationTest::Custom))
  end

  def test_should_not_be_extended_by_the_integration_if_nil
    machine = StateMachines::Machine.new(@klass, integration: nil)
    assert(!(class << machine; ancestors; end).include?(MachineWithCustomIntegrationTest::Custom))
  end

  def test_should_not_be_extended_by_the_integration_if_false
    machine = StateMachines::Machine.new(@klass, integration: false)
    assert(!(class << machine; ancestors; end).include?(MachineWithCustomIntegrationTest::Custom))
  end

  def teardown
    StateMachines::Integrations.reset
    MachineWithCustomIntegrationTest::Custom.class_eval do
      class << self; remove_method :matching_ancestors; end
      def self.matching_ancestors
        ['Vehicle']
      end
    end
  end
end
