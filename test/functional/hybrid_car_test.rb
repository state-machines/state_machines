# frozen_string_literal: true

require 'test_helper'
require 'files/models/hybrid_car'

class HybridCarTest < Minitest::Test
  def setup
    @hybrid_car = HybridCar.new
  end

  def test_should_accept_positional_argument
    assert @hybrid_car.go_green(:eco)
    assert_predicate @hybrid_car, :electric?
    assert_equal 'electric', @hybrid_car.propulsion_mode
    assert_equal :eco, @hybrid_car.driving_profile
  end

  def test_should_accept_keyword_argument
    assert @hybrid_car.go_gas(driving_profile: :sport)
    assert_predicate @hybrid_car, :gas?
    assert_equal 'gas', @hybrid_car.propulsion_mode
    assert_equal :sport, @hybrid_car.driving_profile
  end

  def test_should_accept_positional_and_keyword_arguments
    assert @hybrid_car.go_back_in_time(1995, driving_profile: '1.21 gigawatts')
    assert_predicate @hybrid_car, :flux_capacitor?
    assert_equal 1995, @hybrid_car.target_year
    assert_equal 'flux_capacitor', @hybrid_car.propulsion_mode
    assert_equal '1.21 gigawatts', @hybrid_car.driving_profile
  end

  def test_should_accept_positional_arguments_in_unsafe_method
    assert @hybrid_car.go_green!(:eco)
    assert_predicate @hybrid_car, :electric?
    assert_equal 'electric', @hybrid_car.propulsion_mode
    assert_equal :eco, @hybrid_car.driving_profile
  end

  def test_should_accept_keyword_argument_in_unsafe_method
    assert @hybrid_car.go_gas!(driving_profile: :sport)
    assert_predicate @hybrid_car, :gas?
    assert_equal 'gas', @hybrid_car.propulsion_mode
    assert_equal :sport, @hybrid_car.driving_profile
  end

  def test_should_accept_positional_and_keyword_arguments_in_unsafe_method
    assert @hybrid_car.go_back_in_time!(1995, driving_profile: '1.21 gigawatts')
    assert_predicate @hybrid_car, :flux_capacitor?
    assert_equal 1995, @hybrid_car.target_year
    assert_equal 'flux_capacitor', @hybrid_car.propulsion_mode
    assert_equal '1.21 gigawatts', @hybrid_car.driving_profile
  end

  def test_should_accept_hashes_as_option
    assert @hybrid_car.teleport('wakanda',
                                { engine: :nuclear },
                                { world: :parallel })
    assert_equal 'wakanda', @hybrid_car.destination
    assert_equal({ engine: :nuclear }, @hybrid_car.energy_source)
    assert_equal({ world: :parallel }, @hybrid_car.universe)
  end
end
