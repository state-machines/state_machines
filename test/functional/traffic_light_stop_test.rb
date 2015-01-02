require_relative '../test_helper'
require_relative '../files/models/traffic_light'

class TrafficLightStopTest < MiniTest::Test
  def setup
    @light = TrafficLight.new
    @light.state = 'stop'
  end

  def test_should_use_stop_color
    assert_equal 'red', @light.color
  end

  def test_should_pass_arguments_through
    assert_equal 'RED', @light.color(:upcase!)
  end

  def test_should_pass_block_through
    color = @light.color { |value| value.upcase! }
    assert_equal 'RED', color
  end

  def test_should_use_stop_capture_violations
    assert_equal true, @light.capture_violations?
  end
end
