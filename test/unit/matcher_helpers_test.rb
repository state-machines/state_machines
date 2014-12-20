require 'test_helper'

class MatcherHelpersAllTest < MiniTest::Test
  include StateMachines::MatcherHelpers

  def setup
    @matcher = all
  end

  def test_should_build_an_all_matcher
    assert_equal StateMachines::AllMatcher.instance, @matcher
  end
end

class MatcherHelpersAnyTest < MiniTest::Test
  include StateMachines::MatcherHelpers

  def setup
    @matcher = any
  end

  def test_should_build_an_all_matcher
    assert_equal StateMachines::AllMatcher.instance, @matcher
  end
end

class MatcherHelpersSameTest < MiniTest::Test
  include StateMachines::MatcherHelpers

  def setup
    @matcher = same
  end

  def test_should_build_a_loopback_matcher
    assert_equal StateMachines::LoopbackMatcher.instance, @matcher
  end
end
