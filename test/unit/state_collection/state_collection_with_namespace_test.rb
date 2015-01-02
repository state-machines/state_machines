require_relative '../../test_helper'

class StateCollectionWithNamespaceTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, namespace: 'vehicle')
    @states = StateMachines::StateCollection.new(@machine)

    @states << @state = StateMachines::State.new(@machine, :parked)
    @machine.states.concat(@states)
  end

  def test_should_index_by_name
    assert_equal @state, @states[:parked, :name]
  end

  def test_should_index_by_qualified_name
    assert_equal @state, @states[:vehicle_parked, :qualified_name]
  end
end

