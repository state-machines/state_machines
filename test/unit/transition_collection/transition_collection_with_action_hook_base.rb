# frozen_string_literal: true

# Shared setup for the TransitionCollection action hook tests
module TransitionCollectionWithActionHookBase
  def setup
    @superclass = Class.new do
      def save
        true
      end
    end

    @klass = Class.new(@superclass) do
      attr_reader :saved, :state_on_save, :state_event_on_save, :state_event_transition_on_save

      def save
        @saved = true
        @state_on_save = state
        @state_event_on_save = state_event
        @state_event_transition_on_save = state_event_transition
        super
      end
    end

    @machine = StateMachines::Machine.new(@klass, initial: :parked, action: :save)
    @machine.state :idling
    @machine.event :ignite

    @object = @klass.new

    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end
end
