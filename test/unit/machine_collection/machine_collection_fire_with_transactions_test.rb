require_relative '../../test_helper'

class MachineCollectionFireAttributesWithValidationsTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_accessor :errors

      def initialize
        @errors = []
        super
      end
    end

    @machines = StateMachines::MachineCollection.new
    @machines[:state] = @machine = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
    @machine.event :ignite do
      transition parked: :idling
    end

    class << @machine
      def invalidate(object, _attribute, message, values = [])
        (object.errors ||= []) << generate_message(message, values)
      end

      def reset(object)
        object.errors = []
      end
    end

    @object = @klass.new
  end

  def test_should_invalidate_if_event_is_invalid
    @object.state_event = 'invalid'
    @machines.transitions(@object, :save)

    refute @object.errors.empty?
  end

  def test_should_invalidate_if_no_transition_exists
    @object.state = 'idling'
    @object.state_event = 'ignite'
    @machines.transitions(@object, :save)

    refute @object.errors.empty?
  end

  def test_should_not_invalidate_if_transition_exists
    @object.state_event = 'ignite'
    @machines.transitions(@object, :save)

    assert @object.errors.empty?
  end
end
