require 'spec_helper'

describe StateMachines::MatcherHelpers do
  context 'All' do
    include StateMachines::MatcherHelpers

    before(:each) do
      @matcher = all
    end

    it 'should_build_an_all_matcher' do
      assert_equal StateMachines::AllMatcher.instance, @matcher
    end
  end

  context 'Any' do
    include StateMachines::MatcherHelpers

    before(:each) do
      @matcher = any
    end

    it 'should_build_an_all_matcher' do
      assert_equal StateMachines::AllMatcher.instance, @matcher
    end
  end

  context 'Same' do
    include StateMachines::MatcherHelpers

    before(:each) do
      @matcher = same
    end

    it 'should_build_a_loopback_matcher' do
      assert_equal StateMachines::LoopbackMatcher.instance, @matcher
    end
  end
end
