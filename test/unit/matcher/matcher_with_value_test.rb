require_relative '../../test_helper'

class MatcherWithValueTest < StateMachinesTest
  def setup
    @matcher = StateMachines::Matcher.new(nil)
  end

  def test_should_have_values
    assert_equal [nil], @matcher.values
  end

  def test_should_filter_unknown_values
    assert_equal [nil], @matcher.filter([nil, :parked])
  end
end
