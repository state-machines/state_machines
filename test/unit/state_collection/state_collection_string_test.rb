require_relative '../../test_helper'

class StateCollectionStringTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @states = StateMachines::StateCollection.new(@machine)

    @states << @nil = StateMachines::State.new(@machine, nil)
    @states << @parked = StateMachines::State.new(@machine, 'parked')
    @machine.states.concat(@states)

    @object = @klass.new
  end

  def test_should_index_by_name
    assert_equal @parked, @states['parked', :name]
  end

  def test_should_index_by_name_by_default
    assert_equal @parked, @states['parked']
  end

  def test_should_index_by_symbol_name
    assert_equal @parked, @states[:parked]
  end

  def test_should_index_by_qualified_name
    assert_equal @parked, @states['parked', :qualified_name]
  end

  def test_should_index_by_symbol_qualified_name
    assert_equal @parked, @states[:parked, :qualified_name]
  end
end
