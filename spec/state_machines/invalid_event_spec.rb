require 'spec_helper'
describe StateMachines::InvalidEvent do
  before(:each) do
    @object = Object.new
    @invalid_event = StateMachines::InvalidEvent.new(@object, :invalid)
  end

  it 'should_have_an_object' do
    assert_equal @object, @invalid_event.object
  end

  it 'should_have_an_event' do
    assert_equal :invalid, @invalid_event.event
  end

  it 'should_generate_a_message' do
    assert_equal ':invalid is an unknown state machine event', @invalid_event.message
  end
end