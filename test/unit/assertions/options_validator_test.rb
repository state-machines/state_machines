# frozen_string_literal: true

require 'test_helper'
require 'state_machines/options_validator'

class OptionsValidatorTest < StateMachinesTest
  def test_should_not_raise_exception_if_key_is_valid
    StateMachines::OptionsValidator.assert_valid_keys!({ name: 'foo', value: 'bar' }, :name, :value, :force)
  end

  def test_should_raise_exception_if_key_is_invalid
    exception = assert_raises(ArgumentError) { StateMachines::OptionsValidator.assert_valid_keys!({ name: 'foo', value: 'bar', invalid: true }, :name, :value, :force) }
    assert_equal 'Unknown key: :invalid. Valid keys are: :name, :value, :force', exception.message
  end

  def test_should_include_caller_info_in_error_message
    exception = assert_raises(ArgumentError) { StateMachines::OptionsValidator.assert_valid_keys!({ invalid: true }, :valid, caller_info: 'TestClass#test_method') }
    assert_match(/in TestClass#test_method/, exception.message)
  end
end
