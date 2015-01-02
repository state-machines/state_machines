require_relative '../../test_helper'

class BlacklistMatcherTest < StateMachinesTest
  def setup
    @matcher = StateMachines::BlacklistMatcher.new([:parked, :idling])
  end

  def test_should_have_values
    assert_equal [:parked, :idling], @matcher.values
  end

  def test_should_filter_known_values
    assert_equal [:first_gear], @matcher.filter([:parked, :idling, :first_gear])
  end

  def test_should_match_unknown_values
    assert @matcher.matches?(:first_gear)
  end

  def test_should_not_match_known_values
    refute @matcher.matches?(:parked)
  end

  def test_should_have_a_description
    assert_equal 'all - [:parked, :idling]', @matcher.description

    matcher = StateMachines::BlacklistMatcher.new([:parked])
    assert_equal 'all - :parked', matcher.description
  end
end
