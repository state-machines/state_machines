require_relative '../test_helper'
require_relative '../files/models/traffic_light'

class TrafficLightProceedTest < MiniTest::Test
  def setup
    @light = TrafficLight.new
    @light.state = 'proceed'
  end

  def test_should_use_proceed_color
    assert_equal 'green', @light.color
  end

  def test_should_use_proceed_capture_violations
    assert_equal false, @light.capture_violations?
  end
end
