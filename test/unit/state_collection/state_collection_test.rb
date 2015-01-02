require_relative '../../test_helper'

class StateCollectionTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @states = StateMachines::StateCollection.new(@machine)

    @states << @nil = StateMachines::State.new(@machine, nil)
    @states << @parked = StateMachines::State.new(@machine, :parked)
    @states << @idling = StateMachines::State.new(@machine, :idling)
    @machine.states.concat(@states)

    @object = @klass.new
  end

  def test_should_index_by_name
    assert_equal @parked, @states[:parked, :name]
  end

  def test_should_index_by_name_by_default
    assert_equal @parked, @states[:parked]
  end

  def test_should_index_by_string_name
    assert_equal @parked, @states['parked']
  end

  def test_should_index_by_qualified_name
    assert_equal @parked, @states[:parked, :qualified_name]
  end

  def test_should_index_by_string_qualified_name
    assert_equal @parked, @states['parked', :qualified_name]
  end

  def test_should_index_by_value
    assert_equal @parked, @states['parked', :value]
  end

  def test_should_not_match_if_value_does_not_match
    refute @states.matches?(@object, :parked)
    refute @states.matches?(@object, :idling)
  end

  def test_should_match_if_value_matches
    assert @states.matches?(@object, nil)
  end

  def test_raise_exception_if_matching_invalid_state
    assert_raises(IndexError) { @states.matches?(@object, :invalid) }
  end

  def test_should_find_state_for_object_if_value_is_known
    @object.state = 'parked'
    assert_equal @parked, @states.match(@object)
  end

  def test_should_find_bang_state_for_object_if_value_is_known
    @object.state = 'parked'
    assert_equal @parked, @states.match!(@object)
  end

  def test_should_not_find_state_for_object_with_unknown_value
    @object.state = 'invalid'
    assert_nil @states.match(@object)
  end

  def test_should_raise_exception_if_finding_bang_state_for_object_with_unknown_value
    @object.state = 'invalid'
    exception = assert_raises(ArgumentError) { @states.match!(@object) }
    assert_equal '"invalid" is not a known state value', exception.message
  end
end
