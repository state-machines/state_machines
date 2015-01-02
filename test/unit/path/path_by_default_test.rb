require_relative '../../test_helper'

class PathByDefaultTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @object = @klass.new

    @path = StateMachines::Path.new(@object, @machine)
  end

  def test_should_have_an_object
    assert_equal @object, @path.object
  end

  def test_should_have_a_machine
    assert_equal @machine, @path.machine
  end

  def test_should_not_have_walked_anywhere
    assert_equal [], @path
  end

  def test_should_not_have_a_from_name
    assert_nil @path.from_name
  end

  def test_should_have_no_from_states
    assert_equal [], @path.from_states
  end

  def test_should_not_have_a_to_name
    assert_nil @path.to_name
  end

  def test_should_have_no_to_states
    assert_equal [], @path.to_states
  end

  def test_should_have_no_events
    assert_equal [], @path.events
  end

  def test_should_not_be_able_to_walk_anywhere
    walked = false
    @path.walk { walked = true }
    assert_equal false, walked
  end

  def test_should_not_be_complete
    assert_equal false, @path.complete?
  end
end

