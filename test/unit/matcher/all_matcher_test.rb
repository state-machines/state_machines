require_relative '../../test_helper'

class AllMatcherTest < StateMachinesTest
  def setup
    @matcher = StateMachines::AllMatcher.instance
  end

  def test_should_have_no_values
    assert_equal [], @matcher.values
  end

  def test_should_always_match
    [nil, :parked, :idling].each { |value| assert @matcher.matches?(value) }
  end

  def test_should_not_filter_any_values
    assert_equal [:parked, :idling], @matcher.filter([:parked, :idling])
  end

  def test_should_generate_blacklist_matcher_after_subtraction
    matcher = @matcher - [:parked, :idling]
    assert_instance_of StateMachines::BlacklistMatcher, matcher
    assert_equal [:parked, :idling], matcher.values
  end

  def test_should_have_a_description
    assert_equal 'all', @matcher.description
  end
end
