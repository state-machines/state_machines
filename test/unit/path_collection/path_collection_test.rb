require_relative '../../test_helper'

class PathCollectionTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @object = @klass.new
  end

  def test_should_raise_exception_if_invalid_option_specified
    exception = assert_raises(ArgumentError) { StateMachines::PathCollection.new(@object, @machine, invalid: true) }
    assert_equal 'Unknown key: :invalid. Valid keys are: :from, :to, :deep, :guard', exception.message
  end

  def test_should_raise_exception_if_invalid_from_state_specified
    exception = assert_raises(IndexError) { StateMachines::PathCollection.new(@object, @machine, from: :invalid) }
    assert_equal ':invalid is an invalid name', exception.message
  end

  def test_should_raise_exception_if_invalid_to_state_specified
    exception = assert_raises(IndexError) { StateMachines::PathCollection.new(@object, @machine, to: :invalid) }
    assert_equal ':invalid is an invalid name', exception.message
  end
end
