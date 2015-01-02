require_relative '../../test_helper'

class MatcherHelpersAllTest < StateMachinesTest
  include StateMachines::MatcherHelpers

  def setup
    @matcher = all
  end

  def test_should_build_an_all_matcher
    assert_equal StateMachines::AllMatcher.instance, @matcher
  end
end

