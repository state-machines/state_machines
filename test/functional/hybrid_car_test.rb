require 'test_helper'
require 'files/models/hybrid_car'

class HybridCarTest < MiniTest::Test
  def setup
    @hybrid_car = HybridCar.new
  end

  def test_should_accept_positional_argument
    assert @hybrid_car.go_green(:eco)
    assert @hybrid_car.electric?
    assert_equal @hybrid_car.propulsion_mode, 'electric'
    assert_equal @hybrid_car.driving_profile, :eco
  end

  def test_should_accept_keyword_argument
    assert @hybrid_car.go_gas(driving_profile: :sport)
    assert @hybrid_car.gas?
    assert_equal @hybrid_car.propulsion_mode, 'gas'
    assert_equal @hybrid_car.driving_profile, :sport
  end

  def test_should_accept_positional_and_keyword_arguments
    assert @hybrid_car.go_back_in_time(1995, driving_profile: '1.21 gigawatts')
    assert @hybrid_car.flux_capacitor?
    assert_equal @hybrid_car.target_year, 1995
    assert_equal @hybrid_car.propulsion_mode, 'flux_capacitor'
    assert_equal @hybrid_car.driving_profile, '1.21 gigawatts'
  end

  def test_should_accept_positional_arguments_in_unsafe_method
    assert @hybrid_car.go_green!(:eco)
    assert @hybrid_car.electric?
    assert_equal @hybrid_car.propulsion_mode, 'electric'
    assert_equal @hybrid_car.driving_profile, :eco
  end

  def test_should_accept_keyword_argument_in_unsafe_method
    assert @hybrid_car.go_gas!(driving_profile: :sport)
    assert @hybrid_car.gas?
    assert_equal @hybrid_car.propulsion_mode, 'gas'
    assert_equal @hybrid_car.driving_profile, :sport
  end

  def test_should_accept_positional_and_keyword_arguments_in_unsafe_method
    assert @hybrid_car.go_back_in_time!(1995, driving_profile: '1.21 gigawatts')
    assert @hybrid_car.flux_capacitor?
    assert_equal @hybrid_car.target_year, 1995
    assert_equal @hybrid_car.propulsion_mode, 'flux_capacitor'
    assert_equal @hybrid_car.driving_profile, '1.21 gigawatts'
  end

  def test_should_accept_hashes_as_option
    assert @hybrid_car.teleport('wakanda',
                                { engine: :nuclear } ,
                                { world: :parallel }
    )
    assert_equal @hybrid_car.destination, 'wakanda'
    assert_equal({ engine: :nuclear }, @hybrid_car.energy_source)
    assert_equal({ world: :parallel }, @hybrid_car.universe)
  end
end
