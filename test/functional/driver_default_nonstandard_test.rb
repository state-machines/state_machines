require_relative '../test_helper'
require_relative '../files/models/driver'

class DriverNonstandardTest < MiniTest::Test
  def setup
    @driver = Driver.new
    @events = Driver.state_machine.events
  end

  def test_should_have
    assert_equal 1, @events.transitions_for(@driver).size
  end
end
