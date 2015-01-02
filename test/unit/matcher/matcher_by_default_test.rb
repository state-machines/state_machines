require_relative '../../test_helper'

class MatcherByDefaultTest < StateMachinesTest
  def setup
    @matcher = StateMachines::Matcher.new
  end

  def test_should_have_no_values
    assert_equal [], @matcher.values
  end

  def test_should_filter_all_values
    assert_equal [], @matcher.filter([:parked, :idling])
  end
end
