require_relative '../../test_helper'

class LoopbackMatcherTest < StateMachinesTest
  def setup
    @matcher = StateMachines::LoopbackMatcher.instance
  end

  def test_should_have_no_values
    assert_equal [], @matcher.values
  end

  def test_should_filter_all_values
    assert_equal [], @matcher.filter([:parked, :idling])
  end

  def test_should_match_if_from_context_is_same
    assert @matcher.matches?(:parked, from: :parked)
  end

  def test_should_not_match_if_from_context_is_different
    refute @matcher.matches?(:parked, from: :idling)
  end

  def test_should_have_a_description
    assert_equal 'same', @matcher.description
  end
end
