require_relative '../../test_helper'

class MachineWithIntegrationTest < StateMachinesTest

  module Custom
    include StateMachines::Integrations::Base

    @defaults = {action: :save, use_transactions: false}

    attr_reader :initialized, :with_scopes, :without_scopes, :ran_transaction

    def after_initialize
      @initialized = true
    end

    def create_with_scope(name)
      (@with_scopes ||= []) << name
      lambda {}
    end

    def create_without_scope(name)
      (@without_scopes ||= []) << name
      lambda {}
    end

    def transaction(_)
      @ran_transaction = true
      yield
    end
  end

  def setup
    StateMachines::Integrations.register(MachineWithIntegrationTest::Custom)


    @machine = StateMachines::Machine.new(Class.new, integration: :custom)
  end

  def test_should_call_after_initialize_hook
    assert @machine.initialized
  end

  def test_should_use_the_default_action
    assert_equal :save, @machine.action
  end

  def test_should_use_the_custom_action_if_specified
    machine = StateMachines::Machine.new(Class.new, integration: :custom, action: :save!)
    assert_equal :save!, machine.action
  end

  def test_should_use_the_default_use_transactions
    assert_equal false, @machine.use_transactions
  end

  def test_should_use_the_custom_use_transactions_if_specified
    machine = StateMachines::Machine.new(Class.new, integration: :custom, use_transactions: true)
    assert_equal true, machine.use_transactions
  end

  def test_should_define_a_singular_and_plural_with_scope
    assert_equal %w(with_state with_states), @machine.with_scopes
  end

  def test_should_define_a_singular_and_plural_without_scope
    assert_equal %w(without_state without_states), @machine.without_scopes
  end

  def teardown
    StateMachines::Integrations.reset
  end
end
