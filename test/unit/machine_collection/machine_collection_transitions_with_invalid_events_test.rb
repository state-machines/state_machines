# frozen_string_literal: true

require 'test_helper'

class MachineCollectionTransitionsWithInvalidEventsTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machines = StateMachines::MachineCollection.new
    @machines[:state] = @machine = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
    @machine.event :ignite do
      transition parked: :idling
    end

    @object = @klass.new
    @object.state_event = 'invalid'
    @transitions = @machines.transitions(@object, :save)
  end

  def test_should_be_empty
    assert_empty @transitions
  end

  def test_should_not_perform
    assert_equal false, @transitions.perform
  end
end
