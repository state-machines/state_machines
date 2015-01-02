require_relative '../../test_helper'

class StateCollectionWithStateMatchersTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @states = StateMachines::StateCollection.new(@machine)

    @states << @state = StateMachines::State.new(@machine, :parked, if: lambda { |value| !value.nil? })
    @machine.states.concat(@states)

    @object = @klass.new
    @object.state = 1
  end

  def test_should_match_if_value_matches
    assert @states.matches?(@object, :parked)
  end

  def test_should_not_match_if_value_does_not_match
    @object.state = nil
    refute @states.matches?(@object, :parked)
  end

  def test_should_find_state_for_object_if_value_is_known
    assert_equal @state, @states.match(@object)
  end
end

