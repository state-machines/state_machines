require_relative '../../test_helper'

class MachineCollectionTransitionsWithCustomOptionsTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machines = StateMachines::MachineCollection.new
    @machines[:state] = @machine = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
    @machine.event :ignite do
      transition parked: :idling
    end

    @object = @klass.new
    @transitions = @machines.transitions(@object, :save, after: false)
  end

  def test_should_use_custom_options
    assert @transitions.skip_after
  end
end
