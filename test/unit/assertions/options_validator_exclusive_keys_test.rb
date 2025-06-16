# frozen_string_literal: true

require 'test_helper'
require 'state_machines/options_validator'

class OptionsValidatorExclusiveKeysTest < StateMachinesTest
  def test_should_not_raise_exception_if_no_keys_found
    StateMachines::OptionsValidator.assert_exclusive_keys!({ on: :park }, :only, :except)
  end

  def test_should_not_raise_exception_if_one_key_found
    StateMachines::OptionsValidator.assert_exclusive_keys!({ only: :parked }, :only, :except)
    StateMachines::OptionsValidator.assert_exclusive_keys!({ except: :parked }, :only, :except)
  end

  def test_should_raise_exception_if_two_keys_found
    exception = assert_raises(ArgumentError) { StateMachines::OptionsValidator.assert_exclusive_keys!({ only: :parked, except: :parked }, :only, :except) }
    assert_equal 'Conflicting keys: only, except', exception.message
  end

  def test_should_raise_exception_if_multiple_keys_found
    exception = assert_raises(ArgumentError) { StateMachines::OptionsValidator.assert_exclusive_keys!({ only: :parked, except: :parked, on: :park }, :only, :except, :with) }
    assert_equal 'Conflicting keys: only, except', exception.message
  end

  def test_should_include_caller_info_in_error_message
    exception = assert_raises(ArgumentError) { StateMachines::OptionsValidator.assert_exclusive_keys!({ only: :parked, except: :parked }, :only, :except, caller_info: 'TestClass#test_method') }
    assert_match(/in TestClass#test_method/, exception.message)
  end
end
