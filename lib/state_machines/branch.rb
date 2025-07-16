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
      @if_state_condition = options.delete(:if_state)
      @unless_state_condition = options.delete(:unless_state)
      @if_all_states_condition = options.delete(:if_all_states)
      @unless_all_states_condition = options.delete(:unless_all_states)
      @if_any_state_condition = options.delete(:if_any_state)
      @unless_any_state_condition = options.delete(:unless_any_state)

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
          from = WhitelistMatcher.new(from) unless from.is_a?(Matcher)
          to = WhitelistMatcher.new(to) unless to.is_a?(Matcher)
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
    
    # Alias for Minitest's assert_match
    alias =~ matches?

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
        value.is_a?(Matcher) ? value : WhitelistMatcher.new(options[whitelist_option])
      elsif options.include?(blacklist_option)
        value = options[blacklist_option]
        raise ArgumentError, ":#{blacklist_option} option cannot use matchers; use :#{whitelist_option} instead" if value.is_a?(Matcher)

        BlacklistMatcher.new(value)
      else
        AllMatcher.instance
      end
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
      return true if query[:guard] == false

      # Evaluate original if/unless conditions
      if_passes = !if_condition || Array(if_condition).all? { |condition| evaluate_method_with_event_args(object, condition, event_args) }
      unless_passes = !unless_condition || Array(unless_condition).none? { |condition| evaluate_method_with_event_args(object, condition, event_args) }

      return false unless if_passes && unless_passes

      # Consolidate all state guards
      state_guards = {
        if_state: @if_state_condition,
        unless_state: @unless_state_condition,
        if_all_states: @if_all_states_condition,
        unless_all_states: @unless_all_states_condition,
        if_any_state: @if_any_state_condition,
        unless_any_state: @unless_any_state_condition
      }.compact

      return true if state_guards.empty?

      validate_and_check_state_guards(object, state_guards)
    end

    private

    def validate_and_check_state_guards(object, guards)
      guards.all? do |guard_type, conditions|
        case guard_type
        when :if_state, :if_all_states
          conditions.all? { |machine, state| check_state(object, machine, state) }
        when :unless_state
          conditions.none? { |machine, state| check_state(object, machine, state) }
        when :if_any_state
          conditions.any? { |machine, state| check_state(object, machine, state) }
        when :unless_all_states
          !conditions.all? { |machine, state| check_state(object, machine, state) }
        when :unless_any_state
          conditions.none? { |machine, state| check_state(object, machine, state) }
        end
      end
    end

    def check_state(object, machine_name, state_name)
      machine = object.class.state_machines[machine_name]
      raise ArgumentError, "State machine '#{machine_name}' is not defined for #{object.class.name}" unless machine

      state = machine.states[state_name]
      raise ArgumentError, "State '#{state_name}' is not defined in state machine '#{machine_name}'" unless state

      state.matches?(object.send(machine_name))
    end
  end
end
