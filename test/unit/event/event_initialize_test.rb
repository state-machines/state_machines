# frozen_string_literal: true

require 'test_helper'

class EventInitializeTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
  end

  def test_should_raise_exception_if_invalid_option_specified
    exception = assert_raises(ArgumentError) { StateMachines::Event.new(@machine, :ignite, invalid: true) }
    assert_equal 'Unknown key: :invalid. Valid keys are: :human_name', exception.message
  end

  def test_should_raise_exception_if_invalid_option_specified_with_kwargs
    exception = assert_raises(ArgumentError) { StateMachines::Event.new(@machine, :ignite, nil, invalid: true) }
    assert_equal 'Unknown key: :invalid. Valid keys are: :human_name', exception.message
  end

  def test_should_set_human_name_from_options
    event = StateMachines::Event.new(@machine, :ignite, human_name: 'Start')

    assert_equal 'Start', event.human_name
  end

  def test_should_set_human_name_from_kwargs
    event = StateMachines::Event.new(@machine, :ignite, nil, human_name: 'Start')

    assert_equal 'Start', event.human_name
  end

  def test_should_raise_exception_if_invalid_positional_argument
    exception = assert_raises(ArgumentError) { StateMachines::Event.new(@machine, :ignite, :invalid) }
    assert_equal 'Unexpected positional argument in Event initialize: :invalid', exception.message
  end
end
