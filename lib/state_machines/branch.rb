# frozen_string_literal: true

require_relative 'options_validator'

module StateMachines
  # Represents a set of requirements that must be met in order for a transition
  # or callback to occur.  Branches verify that the event, from state, and to
  # state of the transition match, in addition to if/unless conditionals for
  # an object's state.
  class Branch
    include EvalHelpers

    # The condition that must be met on an object
    attr_reader :if_condition

    # The condition that must *not* be met on an object
    attr_reader :unless_condition

    # The requirement for verifying the event being matched
    attr_reader :event_requirement

    # One or more requirements for verifying the states being matched.  All
    # requirements contain a mapping of {:from => matcher, :to => matcher}.
    attr_reader :state_requirements

    # A list of all of the states known to this branch.  This will pull states
    # from the following options (in the same order):
    # * +from+ / +except_from+
    # * +to+ / +except_to+
    attr_reader :known_states

    # Creates a new branch
    def initialize(options = {}) # :nodoc:
      # Build conditionals
      @if_condition = options.delete(:if)
      @unless_condition = options.delete(:unless)

      # Build event requirement
      @event_requirement = build_matcher(options, :on, :except_on)

      if (options.keys - %i[from to on except_from except_to except_on]).empty?
        # Explicit from/to requirements specified
        @state_requirements = [{ from: build_matcher(options, :from, :except_from), to: build_matcher(options, :to, :except_to) }]
      else
        # Separate out the event requirement
        options.delete(:on)
        options.delete(:except_on)

        # Implicit from/to requirements specified
        @state_requirements = options.collect do |from, to|
          from = WhitelistMatcher.new(from) unless matcher?(from)
          to = WhitelistMatcher.new(to) unless matcher?(to)
          { from: from, to: to }
        end
      end

      # Track known states.  The order that requirements are iterated is based
      # on the priority in which tracked states should be added.
      @known_states = []
      @state_requirements.each do |state_requirement|
        %i[from to].each { |option| @known_states |= state_requirement[option].values }
      end
    end

    # Determines whether the given object / query matches the requirements
    # configured for this branch.  In addition to matching the event, from state,
    # and to state, this will also check whether the configured :if/:unless
    # conditions pass on the given object.
    #
    # == Examples
    #
    #   branch = StateMachines::Branch.new(:parked => :idling, :on => :ignite)
    #
    #   # Successful
    #   branch.matches?(object, :on => :ignite)                                   # => true
    #   branch.matches?(object, :from => nil)                                     # => true
    #   branch.matches?(object, :from => :parked)                                 # => true
    #   branch.matches?(object, :to => :idling)                                   # => true
    #   branch.matches?(object, :from => :parked, :to => :idling)                 # => true
    #   branch.matches?(object, :on => :ignite, :from => :parked, :to => :idling) # => true
    #
    #   # Unsuccessful
    #   branch.matches?(object, :on => :park)                                     # => false
    #   branch.matches?(object, :from => :idling)                                 # => false
    #   branch.matches?(object, :to => :first_gear)                               # => false
    #   branch.matches?(object, :from => :parked, :to => :first_gear)             # => false
    #   branch.matches?(object, :on => :park, :from => :parked, :to => :idling)   # => false
    def matches?(object, query = {})
      !match(object, query).nil?
    end

    # Attempts to match the given object / query against the set of requirements
    # configured for this branch.  In addition to matching the event, from state,
    # and to state, this will also check whether the configured :if/:unless
    # conditions pass on the given object.
    #
    # If a match is found, then the event/state requirements that the query
    # passed successfully will be returned.  Otherwise, nil is returned if there
    # was no match.
    #
    # Query options:
    # * <tt>:from</tt> - One or more states being transitioned from.  If none
    #   are specified, then this will always match.
    # * <tt>:to</tt> - One or more states being transitioned to.  If none are
    #   specified, then this will always match.
    # * <tt>:on</tt> - One or more events that fired the transition.  If none
    #   are specified, then this will always match.
    # * <tt>:guard</tt> - Whether to guard matches with the if/unless
    #   conditionals defined for this branch.  Default is true.
    #
    # Event arguments are passed to guard conditions if they accept multiple parameters.
    #
    # == Examples
    #
    #   branch = StateMachines::Branch.new(:parked => :idling, :on => :ignite)
    #
    #   branch.match(object, :on => :ignite)  # => {:to => ..., :from => ..., :on => ...}
    #   branch.match(object, :on => :park)    # => nil
    def match(object, query = {}, event_args = [])
      StateMachines::OptionsValidator.assert_valid_keys!(query, :from, :to, :on, :guard)

      return unless (match = match_query(query)) && matches_conditions?(object, query, event_args)

      match
    end

    def draw(graph, event, valid_states, io = $stdout)
      machine.renderer.draw_branch(self, graph, event, valid_states, io)
    end

    protected

    # Builds a matcher strategy to use for the given options.  If neither a
    # whitelist nor a blacklist option is specified, then an AllMatcher is
    # built.
    def build_matcher(options, whitelist_option, blacklist_option)
      StateMachines::OptionsValidator.assert_exclusive_keys!(options, whitelist_option, blacklist_option)

      if options.include?(whitelist_option)
        value = options[whitelist_option]
        matcher?(value) ? value : WhitelistMatcher.new(options[whitelist_option])
      elsif options.include?(blacklist_option)
        value = options[blacklist_option]
        raise ArgumentError, ":#{blacklist_option} option cannot use matchers; use :#{whitelist_option} instead" if matcher?(value)

        BlacklistMatcher.new(value)
      else
        AllMatcher.instance
      end
    end

    # Checks if the given value is a matcher (either legacy Matcher class or Data.define matcher)
    def matcher?(value)
      value.is_a?(Matcher) || 
        value.is_a?(WhitelistMatcher) || 
        value.is_a?(BlacklistMatcher) ||
        (value.respond_to?(:matches?) && value.respond_to?(:values))
    end

    # Verifies that all configured requirements (event and state) match the
    # given query.  If a match is found, then a hash containing the
    # event/state requirements that passed will be returned; otherwise, nil.
    def match_query(query)
      query ||= {}

      if match_event(query) && (state_requirement = match_states(query))
        state_requirement.merge(on: event_requirement)
      end
    end

    # Verifies that the event requirement matches the given query
    def match_event(query)
      matches_requirement?(query, :on, event_requirement)
    end

    # Verifies that the state requirements match the given query.  If a
    # matching requirement is found, then it is returned.
    def match_states(query)
      state_requirements.detect do |state_requirement|
        %i[from to].all? { |option| matches_requirement?(query, option, state_requirement[option]) }
      end
    end

    # Verifies that an option in the given query matches the values required
    # for that option
    def matches_requirement?(query, option, requirement)
      !query.include?(option) || requirement.matches?(query[option], query)
    end

    # Verifies that the conditionals for this branch evaluate to true for the
    # given object. Event arguments are passed to guards that accept multiple parameters.
    def matches_conditions?(object, query, event_args = [])
      case [query[:guard], if_condition, unless_condition]
      in [false, _, _]
        true
      in [_, nil, nil]
        true
      in [_, if_conds, nil] if if_conds
        Array(if_conds).all? { |condition| evaluate_method_with_event_args(object, condition, event_args) }
      in [_, nil, unless_conds] if unless_conds
        Array(unless_conds).none? { |condition| evaluate_method_with_event_args(object, condition, event_args) }
      in [_, if_conds, unless_conds] if if_conds || unless_conds
        Array(if_conds).all? { |condition| evaluate_method_with_event_args(object, condition, event_args) } &&
          Array(unless_conds).none? { |condition| evaluate_method_with_event_args(object, condition, event_args) }
      else
        true
      end
    end
  end
end
