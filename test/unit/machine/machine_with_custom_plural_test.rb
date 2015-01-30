require_relative '../../test_helper'

class MachineWithCustomPluralTest < StateMachinesTest
  def setup
    @integration = Module.new do
      include StateMachines::Integrations::Base

      class << self; attr_accessor :with_scopes, :without_scopes; end
      @with_scopes = []
      @without_scopes = []

      def create_with_scope(name)
        MachineWithCustomPluralTest::Custom.with_scopes << name
        lambda {}
      end

      def create_without_scope(name)
        MachineWithCustomPluralTest::Custom.without_scopes << name
        lambda {}
      end
    end

    MachineWithCustomPluralTest.const_set('Custom', @integration)
    StateMachines::Integrations.register(MachineWithCustomPluralTest::Custom)
  end

  def test_should_define_a_singular_and_plural_with_scope
    StateMachines::Machine.new(Class.new, integration: :custom, plural: 'staties')
    assert_equal %w(with_state with_staties), @integration.with_scopes
  end

  def test_should_define_a_singular_and_plural_without_scope
    StateMachines::Machine.new(Class.new, integration: :custom, plural: 'staties')
    assert_equal %w(without_state without_staties), @integration.without_scopes
  end

  def test_should_define_single_with_scope_if_singular_same_as_plural
    StateMachines::Machine.new(Class.new, integration: :custom, plural: 'state')
    assert_equal %w(with_state), @integration.with_scopes
  end

  def test_should_define_single_without_scope_if_singular_same_as_plural
    StateMachines::Machine.new(Class.new, integration: :custom, plural: 'state')
    assert_equal %w(without_state), @integration.without_scopes
  end

  def teardown
    StateMachines::Integrations.reset
    MachineWithCustomPluralTest.send(:remove_const, 'Custom')
  end
end

