# frozen_string_literal: true

require 'test_helper'

class AttributeTransitionCollectionWithAroundAfterYieldCallbackErrorTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machine = StateMachines::Machine.new(@klass, initial: :parked, action: :save)
    @machine.state :idling
    @machine.event :ignite

    @machine.before_transition { raise ArgumentError }

    @object = @klass.new
    @object.state_event = 'ignite'

    @transitions = StateMachines::AttributeTransitionCollection.new([
                                                                      StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                                    ])
    begin
      @transitions.perform
    rescue StandardError
    end
  end

  def test_should_not_clear_event
    assert_equal :ignite, @object.state_event
  end

  def test_should_not_write_event_transition
    assert_nil @object.send(:state_event_transition)
  end
end
