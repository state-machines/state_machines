require_relative '../../test_helper'

class AssertExclusiveKeysTest < StateMachinesTest
  def test_should_not_raise_exception_if_no_keys_found
    { on: :park }.assert_exclusive_keys(:only, :except)
  end

  def test_should_not_raise_exception_if_one_key_found
    { only: :parked }.assert_exclusive_keys(:only, :except)
    { except: :parked }.assert_exclusive_keys(:only, :except)
  end

  def test_should_raise_exception_if_two_keys_found
    exception = assert_raises(ArgumentError) { { only: :parked, except: :parked }.assert_exclusive_keys(:only, :except) }
    assert_equal 'Conflicting keys: only, except', exception.message
  end

  def test_should_raise_exception_if_multiple_keys_found
    exception = assert_raises(ArgumentError) { { only: :parked, except: :parked, on: :park }.assert_exclusive_keys(:only, :except, :with) }
    assert_equal 'Conflicting keys: only, except', exception.message
  end
end
