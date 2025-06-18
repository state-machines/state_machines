# frozen_string_literal: true

require 'test_helper'

class AllMatcherTest < StateMachinesTest
  def setup
    @matcher = StateMachines::AllMatcher.instance
  end

  def test_should_have_no_values
    assert_empty @matcher.values
  end

  def test_should_always_match
    [nil, :parked, :idling].each { |value| assert @matcher.matches?(value) }
  end

  def test_should_not_filter_any_values
    assert_equal %i[parked idling], @matcher.filter(%i[parked idling])
  end

  def test_should_generate_blacklist_matcher_after_subtraction
    matcher = @matcher - %i[parked idling]

    assert_instance_of StateMachines::BlacklistMatcher, matcher
    assert_equal %i[parked idling], matcher.values
  end

  def test_should_have_a_description
    assert_equal 'all', @matcher.description
  end
end
