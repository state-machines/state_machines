require_relative '../../test_helper'

class CallbackTest < StateMachinesTest
  def test_should_raise_exception_if_invalid_type_specified
    exception = assert_raises(ArgumentError) { StateMachines::Callback.new(:invalid) {} }
    assert_equal 'Type must be :before, :after, :around, or :failure', exception.message
  end

  def test_should_not_raise_exception_if_using_before_type
    StateMachines::Callback.new(:before) {}
  end

  def test_should_not_raise_exception_if_using_after_type
    StateMachines::Callback.new(:after) {}
  end

  def test_should_not_raise_exception_if_using_around_type
    StateMachines::Callback.new(:around) {}
  end

  def test_should_not_raise_exception_if_using_failure_type
    StateMachines::Callback.new(:failure) {}
  end

  def test_should_raise_exception_if_no_methods_specified
    exception = assert_raises(ArgumentError) { StateMachines::Callback.new(:before) }
    assert_equal 'Method(s) for callback must be specified', exception.message
  end

  def test_should_not_raise_exception_if_method_specified_in_do_option
    StateMachines::Callback.new(:before, do: :run)
  end

  def test_should_not_raise_exception_if_method_specified_as_argument
    StateMachines::Callback.new(:before, :run)
  end

  def test_should_not_raise_exception_if_method_specified_as_block
    StateMachines::Callback.new(:before, :run) {}
  end

  def test_should_not_raise_exception_if_implicit_option_specified
    StateMachines::Callback.new(:before, do: :run, invalid: :valid)
  end

  def test_should_not_bind_to_objects
    refute StateMachines::Callback.bind_to_object
  end

  def test_should_not_have_a_terminator
    assert_nil StateMachines::Callback.terminator
  end
end
