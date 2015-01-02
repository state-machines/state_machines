require_relative '../../test_helper'

class MatcherHelpersSameTest < StateMachinesTest
  include StateMachines::MatcherHelpers

  def setup
    @matcher = same
  end

  def test_should_build_a_loopback_matcher
    assert_equal StateMachines::LoopbackMatcher.instance, @matcher
  end
end
