require_relative '../../test_helper'

class MatcherHelpersAnyTest < StateMachinesTest
  include StateMachines::MatcherHelpers

  def setup
    @matcher = any
  end

  def test_should_build_an_all_matcher
    assert_equal StateMachines::AllMatcher.instance, @matcher
  end
end

