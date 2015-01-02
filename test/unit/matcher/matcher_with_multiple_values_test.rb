require_relative '../../test_helper'

class MatcherWithMultipleValuesTest < StateMachinesTest
  def setup
    @matcher = StateMachines::Matcher.new([:parked, :idling])
  end

  def test_should_have_values
    assert_equal [:parked, :idling], @matcher.values
  end

  def test_should_filter_unknown_values
    assert_equal [:parked], @matcher.filter([:parked, :first_gear])
  end
end
