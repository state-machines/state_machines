require 'spec_helper'
describe StateMachines::Branch do
  context 'Default' do
    before(:each) do
      @branch = StateMachines::Branch.new(:from => :parked, :to => :idling)
    end

    it 'should_not_raise_exception_if_implicit_option_specified' do
      assert_nothing_raised { StateMachines::Branch.new(:invalid => :valid) }
    end

    it 'should_not_have_an_if_condition' do
      assert_nil @branch.if_condition
    end

    it 'should_not_have_an_unless_condition' do
      assert_nil @branch.unless_condition
    end

    it 'should_have_a_state_requirement' do
      assert_equal 1, @branch.state_requirements.length
    end

    it 'should_raise_an_exception_if_invalid_match_option_specified' do
      assert_raise(ArgumentError) { @branch.match(Object.new, :invalid => true) }
    end
  end

  context 'WithNoRequirements' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new
    end

    it 'should_use_all_matcher_for_event_requirement' do
      assert_equal StateMachines::AllMatcher.instance, @branch.event_requirement
    end

    it 'should_use_all_matcher_for_from_state_requirement' do
      assert_equal StateMachines::AllMatcher.instance, @branch.state_requirements.first[:from]
    end

    it 'should_use_all_matcher_for_to_state_requirement' do
      assert_equal StateMachines::AllMatcher.instance, @branch.state_requirements.first[:to]
    end

    it 'should_match_empty_query' do
      assert @branch.matches?(@object, {})
    end

    it 'should_match_non_empty_query' do
      assert @branch.matches?(@object, :to => :idling, :from => :parked, :on => :ignite)
    end

    it 'should_include_all_requirements_in_match' do
      match = @branch.match(@object, {})

      assert_equal @branch.state_requirements.first[:from], match[:from]
      assert_equal @branch.state_requirements.first[:to], match[:to]
      assert_equal @branch.event_requirement, match[:on]
    end
  end

  context 'WithFromRequirement' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:from => :parked)
    end

    it 'should_use_a_whitelist_matcher' do
      assert_instance_of StateMachines::WhitelistMatcher, @branch.state_requirements.first[:from]
    end

    it 'should_match_if_not_specified' do
      assert @branch.matches?(@object, :to => :idling)
    end

    it 'should_match_if_included' do
      assert @branch.matches?(@object, :from => :parked)
    end

    it 'should_not_match_if_not_included' do
      assert !@branch.matches?(@object, :from => :idling)
    end

    it 'should_not_match_if_nil' do
      assert !@branch.matches?(@object, :from => nil)
    end

    it 'should_ignore_to' do
      assert @branch.matches?(@object, :from => :parked, :to => :idling)
    end

    it 'should_ignore_on' do
      assert @branch.matches?(@object, :from => :parked, :on => :ignite)
    end

    it 'should_be_included_in_known_states' do
      assert_equal [:parked], @branch.known_states
    end

    it 'should_include_requirement_in_match' do
      match = @branch.match(@object, :from => :parked)
      assert_equal @branch.state_requirements.first[:from], match[:from]
    end
  end

  context 'WithMultipleFromRequirements' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:from => [:idling, :parked])
    end

    it 'should_match_if_included' do
      assert @branch.matches?(@object, :from => :idling)
    end

    it 'should_not_match_if_not_included' do
      assert !@branch.matches?(@object, :from => :first_gear)
    end

    it 'should_be_included_in_known_states' do
      assert_equal [:idling, :parked], @branch.known_states
    end
  end

  context 'WithFromMatcherRequirement' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:from => StateMachines::BlacklistMatcher.new([:idling, :parked]))
    end

    it 'should_match_if_included' do
      assert @branch.matches?(@object, :from => :first_gear)
    end

    it 'should_not_match_if_not_included' do
      assert !@branch.matches?(@object, :from => :idling)
    end

    it 'include_values_in_known_states' do
      assert_equal [:idling, :parked], @branch.known_states
    end
  end

  context 'WithToRequirement' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:to => :idling)
    end

    it 'should_use_a_whitelist_matcher' do
      assert_instance_of StateMachines::WhitelistMatcher, @branch.state_requirements.first[:to]
    end

    it 'should_match_if_not_specified' do
      assert @branch.matches?(@object, :from => :parked)
    end

    it 'should_match_if_included' do
      assert @branch.matches?(@object, :to => :idling)
    end

    it 'should_not_match_if_not_included' do
      assert !@branch.matches?(@object, :to => :parked)
    end

    it 'should_not_match_if_nil' do
      assert !@branch.matches?(@object, :to => nil)
    end

    it 'should_ignore_from' do
      assert @branch.matches?(@object, :to => :idling, :from => :parked)
    end

    it 'should_ignore_on' do
      assert @branch.matches?(@object, :to => :idling, :on => :ignite)
    end

    it 'should_be_included_in_known_states' do
      assert_equal [:idling], @branch.known_states
    end

    it 'should_include_requirement_in_match' do
      match = @branch.match(@object, :to => :idling)
      assert_equal @branch.state_requirements.first[:to], match[:to]
    end
  end

  context 'WithMultipleToRequirements' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:to => [:idling, :parked])
    end

    it 'should_match_if_included' do
      assert @branch.matches?(@object, :to => :idling)
    end

    it 'should_not_match_if_not_included' do
      assert !@branch.matches?(@object, :to => :first_gear)
    end

    it 'should_be_included_in_known_states' do
      assert_equal [:idling, :parked], @branch.known_states
    end
  end

  context 'WithToMatcherRequirement' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:to => StateMachines::BlacklistMatcher.new([:idling, :parked]))
    end

    it 'should_match_if_included' do
      assert @branch.matches?(@object, :to => :first_gear)
    end

    it 'should_not_match_if_not_included' do
      assert !@branch.matches?(@object, :to => :idling)
    end

    it 'include_values_in_known_states' do
      assert_equal [:idling, :parked], @branch.known_states
    end
  end

  context 'WithOnRequirement' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:on => :ignite)
    end

    it 'should_use_a_whitelist_matcher' do
      assert_instance_of StateMachines::WhitelistMatcher, @branch.event_requirement
    end

    it 'should_match_if_not_specified' do
      assert @branch.matches?(@object, :from => :parked)
    end

    it 'should_match_if_included' do
      assert @branch.matches?(@object, :on => :ignite)
    end

    it 'should_not_match_if_not_included' do
      assert !@branch.matches?(@object, :on => :park)
    end

    it 'should_not_match_if_nil' do
      assert !@branch.matches?(@object, :on => nil)
    end

    it 'should_ignore_to' do
      assert @branch.matches?(@object, :on => :ignite, :to => :parked)
    end

    it 'should_ignore_from' do
      assert @branch.matches?(@object, :on => :ignite, :from => :parked)
    end

    it 'should_not_be_included_in_known_states' do
      assert_equal [], @branch.known_states
    end

    it 'should_include_requirement_in_match' do
      match = @branch.match(@object, :on => :ignite)
      assert_equal @branch.event_requirement, match[:on]
    end
  end

  context 'WithMultipleOnRequirements' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:on => [:ignite, :park])
    end

    it 'should_match_if_included' do
      assert @branch.matches?(@object, :on => :ignite)
    end

    it 'should_not_match_if_not_included' do
      assert !@branch.matches?(@object, :on => :shift_up)
    end
  end

  context 'WithOnMatcherRequirement' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:on => StateMachines::BlacklistMatcher.new([:ignite, :park]))
    end

    it 'should_match_if_included' do
      assert @branch.matches?(@object, :on => :shift_up)
    end

    it 'should_not_match_if_not_included' do
      assert !@branch.matches?(@object, :on => :ignite)
    end
  end

  context 'WithExceptFromRequirement' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:except_from => :parked)
    end

    it 'should_use_a_blacklist_matcher' do
      assert_instance_of StateMachines::BlacklistMatcher, @branch.state_requirements.first[:from]
    end

    it 'should_match_if_not_included' do
      assert @branch.matches?(@object, :from => :idling)
    end

    it 'should_not_match_if_included' do
      assert !@branch.matches?(@object, :from => :parked)
    end

    it 'should_match_if_nil' do
      assert @branch.matches?(@object, :from => nil)
    end

    it 'should_ignore_to' do
      assert @branch.matches?(@object, :from => :idling, :to => :parked)
    end

    it 'should_ignore_on' do
      assert @branch.matches?(@object, :from => :idling, :on => :ignite)
    end

    it 'should_be_included_in_known_states' do
      assert_equal [:parked], @branch.known_states
    end
  end

  context 'WithMultipleExceptFromRequirements' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:except_from => [:idling, :parked])
    end

    it 'should_match_if_not_included' do
      assert @branch.matches?(@object, :from => :first_gear)
    end

    it 'should_not_match_if_included' do
      assert !@branch.matches?(@object, :from => :idling)
    end

    it 'should_be_included_in_known_states' do
      assert_equal [:idling, :parked], @branch.known_states
    end
  end

  context 'WithExceptFromMatcherRequirement' do
    it 'should_raise_an_exception' do
      assert_raise(ArgumentError) { StateMachines::Branch.new(:except_from => StateMachines::AllMatcher.instance) }
    end
  end

  context 'WithExceptToRequirement' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:except_to => :idling)
    end

    it 'should_use_a_blacklist_matcher' do
      assert_instance_of StateMachines::BlacklistMatcher, @branch.state_requirements.first[:to]
    end

    it 'should_match_if_not_included' do
      assert @branch.matches?(@object, :to => :parked)
    end

    it 'should_not_match_if_included' do
      assert !@branch.matches?(@object, :to => :idling)
    end

    it 'should_match_if_nil' do
      assert @branch.matches?(@object, :to => nil)
    end

    it 'should_ignore_from' do
      assert @branch.matches?(@object, :to => :parked, :from => :idling)
    end

    it 'should_ignore_on' do
      assert @branch.matches?(@object, :to => :parked, :on => :ignite)
    end

    it 'should_be_included_in_known_states' do
      assert_equal [:idling], @branch.known_states
    end
  end

  context 'WithMultipleExceptToRequirements' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:except_to => [:idling, :parked])
    end

    it 'should_match_if_not_included' do
      assert @branch.matches?(@object, :to => :first_gear)
    end

    it 'should_not_match_if_included' do
      assert !@branch.matches?(@object, :to => :idling)
    end

    it 'should_be_included_in_known_states' do
      assert_equal [:idling, :parked], @branch.known_states
    end
  end

  context 'WithExceptToMatcherRequirement' do
    it 'should_raise_an_exception' do
      assert_raise(ArgumentError) { StateMachines::Branch.new(:except_to => StateMachines::AllMatcher.instance) }
    end
  end

  context 'WithExceptOnRequirement' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:except_on => :ignite)
    end

    it 'should_use_a_blacklist_matcher' do
      assert_instance_of StateMachines::BlacklistMatcher, @branch.event_requirement
    end

    it 'should_match_if_not_included' do
      assert @branch.matches?(@object, :on => :park)
    end

    it 'should_not_match_if_included' do
      assert !@branch.matches?(@object, :on => :ignite)
    end

    it 'should_match_if_nil' do
      assert @branch.matches?(@object, :on => nil)
    end

    it 'should_ignore_to' do
      assert @branch.matches?(@object, :on => :park, :to => :idling)
    end

    it 'should_ignore_from' do
      assert @branch.matches?(@object, :on => :park, :from => :parked)
    end

    it 'should_not_be_included_in_known_states' do
      assert_equal [], @branch.known_states
    end
  end

  context 'WithExceptOnMatcherRequirement' do
    it 'should_raise_an_exception' do
      assert_raise(ArgumentError) { StateMachines::Branch.new(:except_on => StateMachines::AllMatcher.instance) }
    end
  end

  context 'WithMultipleExceptOnRequirements' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:except_on => [:ignite, :park])
    end

    it 'should_match_if_not_included' do
      assert @branch.matches?(@object, :on => :shift_up)
    end

    it 'should_not_match_if_included' do
      assert !@branch.matches?(@object, :on => :ignite)
    end
  end

  context 'WithConflictingFromRequirements' do
    it 'should_raise_an_exception' do
      assert_raise(ArgumentError) { StateMachines::Branch.new(:from => :parked, :except_from => :parked) }
    end
  end

  context 'WithConflictingToRequirements' do
    it 'should_raise_an_exception' do
      assert_raise(ArgumentError) { StateMachines::Branch.new(:to => :idling, :except_to => :idling) }
    end
  end

  context 'WithConflictingOnRequirements' do
    it 'should_raise_an_exception' do
      assert_raise(ArgumentError) { StateMachines::Branch.new(:on => :ignite, :except_on => :ignite) }
    end
  end

  context 'WithDifferentRequirements' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:from => :parked, :to => :idling, :on => :ignite)
    end

    it 'should_match_empty_query' do
      assert @branch.matches?(@object)
    end

    it 'should_match_if_all_requirements_match' do
      assert @branch.matches?(@object, :from => :parked, :to => :idling, :on => :ignite)
    end

    it 'should_not_match_if_from_not_included' do
      assert !@branch.matches?(@object, :from => :idling)
    end

    it 'should_not_match_if_to_not_included' do
      assert !@branch.matches?(@object, :to => :parked)
    end

    it 'should_not_match_if_on_not_included' do
      assert !@branch.matches?(@object, :on => :park)
    end

    it 'should_be_nil_if_unmatched' do
      assert_nil @branch.match(@object, :from => :parked, :to => :idling, :on => :park)
    end

    it 'should_include_all_known_states' do
      assert_equal [:parked, :idling], @branch.known_states
    end

    it 'should_not_duplicate_known_statse' do
      branch = StateMachines::Branch.new(:except_from => :idling, :to => :idling, :on => :ignite)
      assert_equal [:idling], branch.known_states
    end
  end

  context 'WithNilRequirements' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:from => nil, :to => nil)
    end

    it 'should_match_empty_query' do
      assert @branch.matches?(@object)
    end

    it 'should_match_if_all_requirements_match' do
      assert @branch.matches?(@object, :from => nil, :to => nil)
    end

    it 'should_not_match_if_from_not_included' do
      assert !@branch.matches?(@object, :from => :parked)
    end

    it 'should_not_match_if_to_not_included' do
      assert !@branch.matches?(@object, :to => :idling)
    end

    it 'should_include_all_known_states' do
      assert_equal [nil], @branch.known_states
    end
  end

  context 'WithImplicitRequirement' do
    before(:each) do
      @branch = StateMachines::Branch.new(:parked => :idling, :on => :ignite)
    end

    it 'should_create_an_event_requirement' do
      assert_instance_of StateMachines::WhitelistMatcher, @branch.event_requirement
      assert_equal [:ignite], @branch.event_requirement.values
    end

    it 'should_use_a_whitelist_from_matcher' do
      assert_instance_of StateMachines::WhitelistMatcher, @branch.state_requirements.first[:from]
    end

    it 'should_use_a_whitelist_to_matcher' do
      assert_instance_of StateMachines::WhitelistMatcher, @branch.state_requirements.first[:to]
    end
  end

  context 'WithMultipleImplicitRequirements' do
    before(:each) do
      @object = Object.new
      @branch = StateMachines::Branch.new(:parked => :idling, :idling => :first_gear, :on => :ignite)
    end

    it 'should_create_multiple_state_requirements' do
      assert_equal 2, @branch.state_requirements.length
    end

    it 'should_not_match_event_as_state_requirement' do
      assert !@branch.matches?(@object, :from => :on, :to => :ignite)
    end

    it 'should_match_if_from_included_in_any' do
      assert @branch.matches?(@object, :from => :parked)
      assert @branch.matches?(@object, :from => :idling)
    end

    it 'should_not_match_if_from_not_included_in_any' do
      assert !@branch.matches?(@object, :from => :first_gear)
    end

    it 'should_match_if_to_included_in_any' do
      assert @branch.matches?(@object, :to => :idling)
      assert @branch.matches?(@object, :to => :first_gear)
    end

    it 'should_not_match_if_to_not_included_in_any' do
      assert !@branch.matches?(@object, :to => :parked)
    end

    it 'should_match_if_all_options_match' do
      assert @branch.matches?(@object, :from => :parked, :to => :idling, :on => :ignite)
      assert @branch.matches?(@object, :from => :idling, :to => :first_gear, :on => :ignite)
    end

    it 'should_not_match_if_any_options_do_not_match' do
      assert !@branch.matches?(@object, :from => :parked, :to => :idling, :on => :park)
      assert !@branch.matches?(@object, :from => :parked, :to => :first_gear, :on => :park)
    end

    it 'should_include_all_known_states' do
      assert_equal [:first_gear, :idling, :parked], @branch.known_states.sort_by { |state| state.to_s }
    end

    it 'should_not_duplicate_known_statse' do
      branch = StateMachines::Branch.new(:parked => :idling, :first_gear => :idling)
      assert_equal [:first_gear, :idling, :parked], branch.known_states.sort_by { |state| state.to_s }
    end
  end

  context 'WithImplicitFromRequirementMatcher' do
    before(:each) do
      @matcher = StateMachines::BlacklistMatcher.new(:parked)
      @branch = StateMachines::Branch.new(@matcher => :idling)
    end

    it 'should_not_convert_from_to_whitelist_matcher' do
      assert_equal @matcher, @branch.state_requirements.first[:from]
    end

    it 'should_convert_to_to_whitelist_matcher' do
      assert_instance_of StateMachines::WhitelistMatcher, @branch.state_requirements.first[:to]
    end
  end

  context 'WithImplicitToRequirementMatcher' do
    before(:each) do
      @matcher = StateMachines::BlacklistMatcher.new(:idling)
      @branch = StateMachines::Branch.new(:parked => @matcher)
    end

    it 'should_convert_from_to_whitelist_matcher' do
      assert_instance_of StateMachines::WhitelistMatcher, @branch.state_requirements.first[:from]
    end

    it 'should_not_convert_to_to_whitelist_matcher' do
      assert_equal @matcher, @branch.state_requirements.first[:to]
    end
  end

  context 'WithImplicitAndExplicitRequirements' do
    before(:each) do
      @branch = StateMachines::Branch.new(:parked => :idling, :from => :parked)
    end

    it 'should_create_multiple_requirements' do
      assert_equal 2, @branch.state_requirements.length
    end

    it 'should_create_implicit_requirements_for_implicit_options' do
      assert(@branch.state_requirements.any? do |state_requirement|
        state_requirement[:from].values == [:parked] && state_requirement[:to].values == [:idling]
      end)
    end

    it 'should_create_implicit_requirements_for_explicit_options' do
      assert(@branch.state_requirements.any? do |state_requirement|
        state_requirement[:from].values == [:from] && state_requirement[:to].values == [:parked]
      end)
    end
  end

  context 'WithIfConditional' do
    before(:each) do
      @object = Object.new
    end

    it 'should_have_an_if_condition' do
      branch = StateMachines::Branch.new(:if => lambda { true })
      assert_not_nil branch.if_condition
    end

    it 'should_match_if_true' do
      branch = StateMachines::Branch.new(:if => lambda { true })
      assert branch.matches?(@object)
    end

    it 'should_not_match_if_false' do
      branch = StateMachines::Branch.new(:if => lambda { false })
      assert !branch.matches?(@object)
    end

    it 'should_be_nil_if_unmatched' do
      branch = StateMachines::Branch.new(:if => lambda { false })
      assert_nil branch.match(@object)
    end
  end

  context 'WithMultipleIfConditionals' do
    before(:each) do
      @object = Object.new
    end

    it 'should_match_if_all_are_true' do
      branch = StateMachines::Branch.new(:if => [lambda { true }, lambda { true }])
      assert branch.match(@object)
    end

    it 'should_not_match_if_any_are_false' do
      branch = StateMachines::Branch.new(:if => [lambda { true }, lambda { false }])
      assert !branch.match(@object)

      branch = StateMachines::Branch.new(:if => [lambda { false }, lambda { true }])
      assert !branch.match(@object)
    end
  end

  context 'WithUnlessConditional' do
    before(:each) do
      @object = Object.new
    end

    it 'should_have_an_unless_condition' do
      branch = StateMachines::Branch.new(:unless => lambda { true })
      assert_not_nil branch.unless_condition
    end

    it 'should_match_if_false' do
      branch = StateMachines::Branch.new(:unless => lambda { false })
      assert branch.matches?(@object)
    end

    it 'should_not_match_if_true' do
      branch = StateMachines::Branch.new(:unless => lambda { true })
      assert !branch.matches?(@object)
    end

    it 'should_be_nil_if_unmatched' do
      branch = StateMachines::Branch.new(:unless => lambda { true })
      assert_nil branch.match(@object)
    end
  end

  context 'WithMultipleUnlessConditionals' do
    before(:each) do
      @object = Object.new
    end

    it 'should_match_if_all_are_false' do
      branch = StateMachines::Branch.new(:unless => [lambda { false }, lambda { false }])
      assert branch.match(@object)
    end

    it 'should_not_match_if_any_are_true' do
      branch = StateMachines::Branch.new(:unless => [lambda { true }, lambda { false }])
      assert !branch.match(@object)

      branch = StateMachines::Branch.new(:unless => [lambda { false }, lambda { true }])
      assert !branch.match(@object)
    end
  end

  context 'WithConflictingConditionals' do
    before(:each) do
      @object = Object.new
    end

    it 'should_match_if_if_is_true_and_unless_is_false' do
      branch = StateMachines::Branch.new(:if => lambda { true }, :unless => lambda { false })
      assert branch.match(@object)
    end

    it 'should_not_match_if_if_is_false_and_unless_is_true' do
      branch = StateMachines::Branch.new(:if => lambda { false }, :unless => lambda { true })
      assert !branch.match(@object)
    end

    it 'should_not_match_if_if_is_false_and_unless_is_false' do
      branch = StateMachines::Branch.new(:if => lambda { false }, :unless => lambda { false })
      assert !branch.match(@object)
    end

    it 'should_not_match_if_if_is_true_and_unless_is_true' do
      branch = StateMachines::Branch.new(:if => lambda { true }, :unless => lambda { true })
      assert !branch.match(@object)
    end
  end

  context 'WithoutGuards' do
    before(:each) do
      @object = Object.new
    end

    it 'should_match_if_if_is_false' do
      branch = StateMachines::Branch.new(:if => lambda { false })
      assert branch.matches?(@object, :guard => false)
    end

    it 'should_match_if_if_is_true' do
      branch = StateMachines::Branch.new(:if => lambda { true })
      assert branch.matches?(@object, :guard => false)
    end

    it 'should_match_if_unless_is_false' do
      branch = StateMachines::Branch.new(:unless => lambda { false })
      assert branch.matches?(@object, :guard => false)
    end

    it 'should_match_if_unless_is_true' do
      branch = StateMachines::Branch.new(:unless => lambda { true })
      assert branch.matches?(@object, :guard => false)
    end
  end
end