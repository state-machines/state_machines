require_relative '../../test_helper'

class StateWithNamespaceTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, namespace: 'alarm')
    @machine.states << @state = StateMachines::State.new(@machine, :active)
    @object = @klass.new
  end

  def test_should_have_a_name
    assert_equal :active, @state.name
  end

  def test_should_have_a_qualified_name
    assert_equal :alarm_active, @state.qualified_name
  end

  def test_should_namespace_predicate
    assert @object.respond_to?(:alarm_active?)
  end
end
