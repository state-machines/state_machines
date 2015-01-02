require_relative '../../test_helper'

class EventWithMarshallingTest < StateMachinesTest
  def setup
    @klass = Class.new do
      def save
        true
      end
    end
    self.class.const_set('Example', @klass)

    @machine = StateMachines::Machine.new(@klass, action: :save)
    @machine.state :parked, :idling

    @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
    @event.transition(parked: :idling)

    @object = @klass.new
    @object.state = 'parked'
  end

  def test_should_marshal_during_before_callbacks
    @machine.before_transition { |object, _transition| Marshal.dump(object) }
    @event.fire(@object)
  end

  def test_should_marshal_during_action
    @klass.class_eval do
      remove_method :save

      def save
        Marshal.dump(self)
      end
    end

    @event.fire(@object)
  end

  def test_should_marshal_during_after_callbacks
    @machine.after_transition { |object, _transition| Marshal.dump(object) }
    @event.fire(@object)
  end

  def teardown
    self.class.send(:remove_const, 'Example')
  end
end
