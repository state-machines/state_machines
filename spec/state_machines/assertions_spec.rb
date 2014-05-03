require 'spec_helper'


context 'AssertValidKeys' do
  it 'should_not_raise_exception_if_key_is_valid' do
    assert_nothing_raised { {:name => 'foo', :value => 'bar'}.assert_valid_keys(:name, :value, :force) }
  end

  it 'should_raise_exception_if_key_is_invalid' do
    assert_raise(ArgumentError) { {:name => 'foo', :value => 'bar', :invalid => true}.assert_valid_keys(:name, :value, :force) }
  end
end

context 'AssertExclusiveKeys' do
  it 'should_not_raise_exception_if_no_keys_found' do
    assert_nothing_raised { {:on => :park}.assert_exclusive_keys(:only, :except) }
  end

  it 'should_not_raise_exception_if_one_key_found' do
    assert_nothing_raised { {:only => :parked}.assert_exclusive_keys(:only, :except) }
    assert_nothing_raised { {:except => :parked}.assert_exclusive_keys(:only, :except) }
  end

  it 'should_raise_exception_if_two_keys_found' do
    assert_raise(ArgumentError) { {:only => :parked, :except => :parked}.assert_exclusive_keys(:only, :except) }
  end

  it 'should_raise_exception_if_multiple_keys_found' do
    assert_raise(ArgumentError) { {:only => :parked, :except => :parked, :on => :park}.assert_exclusive_keys(:only, :except, :with) }
  end
end