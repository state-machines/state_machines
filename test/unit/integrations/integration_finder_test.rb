require_relative '../../test_helper'

class IntegrationFinderTest < StateMachinesTest
  def setup
    StateMachines::Integrations.reset
  end

  def test_should_raise_an_exception_if_invalid
    exception = assert_raises(StateMachines::IntegrationNotFound) { StateMachines::Integrations.find_by_name(:invalid) }
    assert_equal ':invalid is an invalid integration. No integrations registered', exception.message
  end

  def test_should_have_no_integrations
    assert_equal([], StateMachines::Integrations.list)
  end
end
