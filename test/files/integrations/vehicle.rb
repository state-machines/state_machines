# frozen_string_literal: true

module VehicleIntegration
  include StateMachines::Integrations::Base

  def self.matching_ancestors
    [Vehicle]
  end
end
