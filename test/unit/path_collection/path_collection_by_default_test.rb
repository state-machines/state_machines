require_relative '../../test_helper'

class PathCollectionByDefaultTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked

    @object = @klass.new
    @object.state = 'parked'

    @paths = StateMachines::PathCollection.new(@object, @machine)
  end

  def test_should_have_an_object
    assert_equal @object, @paths.object
  end

  def test_should_have_a_machine
    assert_equal @machine, @paths.machine
  end

  def test_should_have_a_from_name
    assert_equal :parked, @paths.from_name
  end

  def test_should_not_have_a_to_name
    assert_nil @paths.to_name
  end

  def test_should_have_no_from_states
    assert_equal [], @paths.from_states
  end

  def test_should_have_no_to_states
    assert_equal [], @paths.to_states
  end

  def test_should_have_no_events
    assert_equal [], @paths.events
  end

  def test_should_have_no_paths
    assert @paths.empty?
  end
end
