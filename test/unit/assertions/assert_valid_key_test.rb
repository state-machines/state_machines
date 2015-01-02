require_relative '../../test_helper'

class AssertValidKeysTest < StateMachinesTest
  def test_should_not_raise_exception_if_key_is_valid
    { name: 'foo', value: 'bar' }.assert_valid_keys(:name, :value, :force)
  end

  def test_should_raise_exception_if_key_is_invalid
    exception = assert_raises(ArgumentError) { { name: 'foo', value: 'bar', invalid: true }.assert_valid_keys(:name, :value, :force) }
    assert_equal 'Unknown key: :invalid. Valid keys are: :name, :value, :force', exception.message
  end
end
