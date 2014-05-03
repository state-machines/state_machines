require 'spec_helper'

describe StateMachines::InvalidParallelTransition do
  before(:each) do
    @object = Object.new
    @events = [:ignite, :disable_alarm]

    @invalid_transition = StateMachines::InvalidParallelTransition.new(@object, @events)
  end

  it 'should_have_an_object' do
    expect(@invalid_transition.object).to eq(@object)
  end

  it 'should_have_events' do
    expect(@invalid_transition.events).to eq(@events)
  end
end