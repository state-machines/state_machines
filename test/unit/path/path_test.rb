require_relative '../../test_helper'

class PathTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @object = @klass.new
  end

  def test_should_raise_exception_if_invalid_option_specified
    exception = assert_raises(ArgumentError) { StateMachines::Path.new(@object, @machine, invalid: true) }
    assert_equal 'Unknown key: :invalid. Valid keys are: :target, :guard', exception.message
  end
end