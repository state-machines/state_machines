# frozen_string_literal: true

require 'test_helper'
require 'files/models/vehicle'

class VehicleRepairedTest < Minitest::Test
  def setup
    @vehicle = Vehicle.new
    @vehicle.ignite
    @vehicle.shift_up
    @vehicle.crash
    @vehicle.repair
  end

  def test_should_be_in_parked_state
    assert_equal 'parked', @vehicle.state
  end

  def test_should_not_have_a_busy_auto_shop
    assert_predicate @vehicle.auto_shop, :available?
  end
end
