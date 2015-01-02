require_relative '../../test_helper'

class InvalidEventTest < StateMachinesTest
  def setup
    @object = Object.new
    @invalid_event = StateMachines::InvalidEvent.new(@object, :invalid)
  end

  def test_should_have_an_object
    assert_equal @object, @invalid_event.object
  end

  def test_should_have_an_event
    assert_equal :invalid, @invalid_event.event
  end

  def test_should_generate_a_message
    assert_equal ':invalid is an unknown state machine event', @invalid_event.message
  end
end
