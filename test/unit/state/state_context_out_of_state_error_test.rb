# frozen_string_literal: true

require 'test_helper'

class StateContextOutOfStateErrorTest < StateMachinesTest
  def setup
    @klass = Class.new do
      state_machine(initial: :parked) do
        event(:ignite) { transition parked: :idling }
        state(:parked) { def speed(gear) = gear }
      end
    end
    @object = @klass.new
    @object.ignite
  end

  def test_should_raise_a_no_method_error
    error = assert_raises(NoMethodError) { @object.speed(2) }

    assert_kind_of StateMachines::InvalidContext, error
  end

  def test_should_describe_the_call
    error = assert_raises(StateMachines::InvalidContext) { @object.speed(2) }

    assert_equal [:speed, [2]], [error.name, error.args]
  end

  def test_should_carry_the_object_as_receiver
    error = assert_raises(StateMachines::InvalidContext) { @object.speed(2) }

    assert_same @object, error.receiver
    assert_same @object, error.object
  end

  def test_should_name_the_state
    error = assert_raises(StateMachines::InvalidContext) { @object.speed(2) }

    assert_equal 'State :idling for :state is not a valid context for calling #speed', error.message
  end
end
