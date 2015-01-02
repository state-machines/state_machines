require_relative '../../test_helper'

class WhitelistMatcherTest < StateMachinesTest
  def setup
    @matcher = StateMachines::WhitelistMatcher.new([:parked, :idling])
  end

  def test_should_have_values
    assert_equal [:parked, :idling], @matcher.values
  end

  def test_should_filter_unknown_values
    assert_equal [:parked, :idling], @matcher.filter([:parked, :idling, :first_gear])
  end

  def test_should_match_known_values
    assert @matcher.matches?(:parked)
  end

  def test_should_not_match_unknown_values
    refute @matcher.matches?(:first_gear)
  end

  def test_should_have_a_description
    assert_equal '[:parked, :idling]', @matcher.description

    matcher = StateMachines::WhitelistMatcher.new([:parked])
    assert_equal ':parked', matcher.description
  end
end
