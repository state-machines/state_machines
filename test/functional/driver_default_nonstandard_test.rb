# frozen_string_literal: true

require 'test_helper'
require 'files/models/driver'

class DriverNonstandardTest < Minitest::Test
  def setup
    @driver = Driver.new
    @events = Driver.state_machine.events
  end

  def test_should_have
    assert_equal 1, @events.transitions_for(@driver).size
  end
end
