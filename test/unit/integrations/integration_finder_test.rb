require_relative '../../test_helper'

class IntegrationFinderTest < StateMachinesTest
  def setup
    StateMachines::Integrations.reset
  end

  def test_should_find_base
    assert_equal StateMachines::Integrations::Base, StateMachines::Integrations.find_by_name(:base)
  end

  def test_should_raise_an_exception_if_invalid
    exception = assert_raises(StateMachines::IntegrationNotFound) { StateMachines::Integrations.find_by_name(:invalid) }
    assert_equal ':invalid is an invalid integration. Valid integrations are: base ', exception.message
  end
end
