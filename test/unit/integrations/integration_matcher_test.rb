require_relative '../../test_helper'
require_relative '../../files/models/vehicle'
require_relative '../../files/integrations/vehicle'

class IntegrationMatcherTest < StateMachinesTest
  def setup
    StateMachines::Integrations.reset
  end

  def test_should_return_nil_if_no_match_found
    assert_nil StateMachines::Integrations.match(Vehicle)
  end

  def test_should_return_integration_class_if_match_found
    StateMachines::Integrations.register(VehicleIntegration)
    assert_equal VehicleIntegration, StateMachines::Integrations.match(Vehicle)
  end

  def test_should_return_nil_if_no_match_found_with_ancestors
    assert_nil StateMachines::Integrations.match_ancestors(['Fake'])
  end

  def test_should_return_integration_class_if_match_found_with_ancestors
    StateMachines::Integrations.register(VehicleIntegration)
    assert_equal VehicleIntegration, StateMachines::Integrations.match_ancestors(['Fake', 'Vehicle'])
  end
end
