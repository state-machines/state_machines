# frozen_string_literal: true

require 'test_helper'

class AttributeTransitionCollectionMarshallingTest < StateMachinesTest
  def setup
    @klass = Class.new
    self.class.const_set('Example', @klass)

    @machine = StateMachines::Machine.new(@klass, initial: :parked, action: :save)
    @machine.state :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state_event = 'ignite'
  end

  def teardown
    self.class.send(:remove_const, 'Example')
  end

  def test_should_marshal_during_before_callbacks
    @machine.before_transition { |object, _transition| Marshal.dump(object) }
    transitions(after: false).perform { true }
    transitions.perform { true }
  end

  def test_should_marshal_during_action
    transitions(after: false).perform do
      Marshal.dump(@object)
      true
    end

    transitions.perform do
      Marshal.dump(@object)
      true
    end
  end

  def test_should_marshal_during_after_callbacks
    @machine.after_transition { |object, _transition| Marshal.dump(object) }
    transitions(after: false).perform { true }
    transitions.perform { true }
  end

  def test_should_marshal_during_around_callbacks_before_yield
    @machine.around_transition do |object, _transition, block|
      Marshal.dump(object)
      block.call
    end
    transitions(after: false).perform { true }
    transitions.perform { true }
  end

  def test_should_marshal_during_around_callbacks_after_yield
    @machine.around_transition do |object, _transition, block|
      block.call
      Marshal.dump(object)
    end
    transitions(after: false).perform { true }
    transitions.perform { true }
  end

  private

  def transitions(options = {})
    StateMachines::AttributeTransitionCollection.new([
                                                       StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                     ], options)
  end
end
