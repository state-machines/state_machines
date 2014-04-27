require 'spec_helper'

describe StateMachines::Matcher do
  context 'ByDefault' do
    before(:each) do
      @matcher = StateMachines::Matcher.new
    end

    it 'should_have_no_values' do
      assert_equal [], @matcher.values
    end

    it 'should_filter_all_values' do
      assert_equal [], @matcher.filter([:parked, :idling])
    end
  end

  context 'WithValue' do
    before(:each) do
      @matcher = StateMachines::Matcher.new(nil)
    end

    it 'should_have_values' do
      assert_equal [nil], @matcher.values
    end

    it 'should_filter_unknown_values' do
      assert_equal [nil], @matcher.filter([nil, :parked])
    end
  end

  context 'WithMultipleValues' do
    before(:each) do
      @matcher = StateMachines::Matcher.new([:parked, :idling])
    end

    it 'should_have_values' do
      assert_equal [:parked, :idling], @matcher.values
    end

    it 'should_filter_unknown_values' do
      assert_equal [:parked], @matcher.filter([:parked, :first_gear])
    end
  end

  context 'AllMatcher' do
    before(:each) do
      @matcher = StateMachines::AllMatcher.instance
    end

    it 'should_have_no_values' do
      assert_equal [], @matcher.values
    end

    it 'should_always_match' do
      [nil, :parked, :idling].each { |value| assert @matcher.matches?(value) }
    end

    it 'should_not_filter_any_values' do
      assert_equal [:parked, :idling], @matcher.filter([:parked, :idling])
    end

    it 'should_generate_blacklist_matcher_after_subtraction' do
      matcher = @matcher - [:parked, :idling]
      assert_instance_of StateMachines::BlacklistMatcher, matcher
      assert_equal [:parked, :idling], matcher.values
    end

    it 'should_have_a_description' do
      assert_equal 'all', @matcher.description
    end
  end

  context 'WhitelistMatcher' do
    before(:each) do
      @matcher = StateMachines::WhitelistMatcher.new([:parked, :idling])
    end

    it 'should_have_values' do
      assert_equal [:parked, :idling], @matcher.values
    end

    it 'should_filter_unknown_values' do
      assert_equal [:parked, :idling], @matcher.filter([:parked, :idling, :first_gear])
    end

    it 'should_match_known_values' do
      assert @matcher.matches?(:parked)
    end

    it 'should_not_match_unknown_values' do
      assert !@matcher.matches?(:first_gear)
    end

    it 'should_have_a_description' do
      assert_equal '[:parked, :idling]', @matcher.description

      matcher = StateMachines::WhitelistMatcher.new([:parked])
      assert_equal ':parked', matcher.description
    end
  end

  context 'BlacklistMatcher' do
    before(:each) do
      @matcher = StateMachines::BlacklistMatcher.new([:parked, :idling])
    end

    it 'should_have_values' do
      assert_equal [:parked, :idling], @matcher.values
    end

    it 'should_filter_known_values' do
      assert_equal [:first_gear], @matcher.filter([:parked, :idling, :first_gear])
    end

    it 'should_match_unknown_values' do
      assert @matcher.matches?(:first_gear)
    end

    it 'should_not_match_known_values' do
      assert !@matcher.matches?(:parked)
    end

    it 'should_have_a_description' do
      assert_equal 'all - [:parked, :idling]', @matcher.description

      matcher = StateMachines::BlacklistMatcher.new([:parked])
      assert_equal 'all - :parked', matcher.description
    end
  end

  context 'LoopbackMatcher' do
    before(:each) do
      @matcher = StateMachines::LoopbackMatcher.instance
    end

    it 'should_have_no_values' do
      assert_equal [], @matcher.values
    end

    it 'should_filter_all_values' do
      assert_equal [], @matcher.filter([:parked, :idling])
    end

    it 'should_match_if_from_context_is_same' do
      assert @matcher.matches?(:parked, :from => :parked)
    end

    it 'should_not_match_if_from_context_is_different' do
      assert !@matcher.matches?(:parked, :from => :idling)
    end

    it 'should_have_a_description' do
      assert_equal 'same', @matcher.description
    end
  end
end
