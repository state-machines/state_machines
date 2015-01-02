require_relative '../test_helper'
require_relative '../files/models/traffic_light'

class TrafficLightCautionTest < MiniTest::Test
  def setup
    @light = TrafficLight.new
    @light.state = 'caution'
  end

  def test_should_use_caution_color
    assert_equal 'yellow', @light.color
  end

  def test_should_use_caution_capture_violations
    assert_equal true, @light.capture_violations?
  end
end
