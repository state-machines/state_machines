require_relative '../../test_helper'

class MachineWithFailureCallbacksTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_accessor :callbacks
    end

    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @event = @machine.event :ignite

    @object = @klass.new
    @object.callbacks = []
  end

  def test_should_raise_exception_if_implicit_option_specified
    exception = assert_raises(ArgumentError) { @machine.after_failure invalid: :valid, do: lambda {} }
    assert_equal 'Unknown key: :invalid. Valid keys are: :on, :do, :if, :unless', exception.message
  end

  def test_should_raise_exception_if_method_not_specified
    exception = assert_raises(ArgumentError) { @machine.after_failure on: :ignite }
    assert_equal 'Method(s) for callback must be specified', exception.message
  end

  def test_should_invoke_callbacks_during_failed_transition
    @machine.after_failure lambda { |object| object.callbacks << 'failure' }

    @event.fire(@object)
    assert_equal %w(failure), @object.callbacks
  end

  def test_should_allow_multiple_callbacks
    @machine.after_failure lambda { |object| object.callbacks << 'failure1' }, lambda { |object| object.callbacks << 'failure2' }

    @event.fire(@object)
    assert_equal %w(failure1 failure2), @object.callbacks
  end

  def test_should_allow_multiple_callbacks_with_requirements
    @machine.after_failure lambda { |object| object.callbacks << 'failure_ignite1' }, lambda { |object| object.callbacks << 'failure_ignite2' }, on: :ignite
    @machine.after_failure lambda { |object| object.callbacks << 'failure_park1' }, lambda { |object| object.callbacks << 'failure_park2' }, on: :park

    @event.fire(@object)
    assert_equal %w(failure_ignite1 failure_ignite2), @object.callbacks
  end
end

