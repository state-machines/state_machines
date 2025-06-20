# frozen_string_literal: true

module StateMachines
  # Provides a general strategy pattern for determining whether a match is found
  # for a value.  The algorithm that actually determines the match depends on
  # the matcher in use.
  class Matcher
    # The list of values against which queries are matched
    attr_reader :values

    # Creates a new matcher for querying against the given set of values
    def initialize(values = [])
      @values = values.is_a?(Array) ? values : [values]
    end

    # Generates a subset of values that exists in both the set of values being
    # filtered and the values configured for the matcher
    def filter(values)
      self.values & values
    end
  end

  # Matches any given value.  Since there is no configuration for this type of
  # matcher, it must be used as a singleton.
  class AllMatcher < Matcher
    include Singleton

    # Generates a blacklist matcher based on the given set of values
    #
    # == Examples
    #
    #   matcher = StateMachines::AllMatcher.instance - [:parked, :idling]
    #   matcher.matches?(:parked)       # => false
    #   matcher.matches?(:first_gear)   # => true
    def -(other)
      BlacklistMatcher.new(other)
    end
    alias except -

    # Always returns true
    def matches?(_value, _context = {})
      true
    end

    # Always returns the given set of values
    def filter(values)
      values
    end

    # A human-readable description of this matcher.  Always "all".
    def description
      'all'
    end
  end

  # Matches a specific set of values
  class WhitelistMatcher < Data.define(:values)
    # Creates a new whitelist matcher for querying against the given set of values
    def self.new(values = [])
      normalized_values = values.is_a?(Array) ? values : [values]
      super(normalized_values)
    end

    # Checks whether the given value exists within the whitelist configured
    # for this matcher.
    #
    # == Examples
    #
    #   matcher = StateMachines::WhitelistMatcher.new([:parked, :idling])
    #   matcher.matches?(:parked)       # => true
    #   matcher.matches?(:first_gear)   # => false
    def matches?(value, _context = {})
      values.include?(value)
    end

    # Generates a subset of values that exists in both the set of values being
    # filtered and the values configured for the matcher
    def filter(values)
      self.values & values
    end

    # A human-readable description of this matcher
    def description
      values.length == 1 ? values.first.inspect : values.inspect
    end
  end

  # Matches everything but a specific set of values
  class BlacklistMatcher < Data.define(:values)
    # Creates a new blacklist matcher for querying against the given set of values
    def self.new(values = [])
      normalized_values = values.is_a?(Array) ? values : [values]
      super(normalized_values)
    end

    # Checks whether the given value exists outside the blacklist configured
    # for this matcher.
    #
    # == Examples
    #
    #   matcher = StateMachines::BlacklistMatcher.new([:parked, :idling])
    #   matcher.matches?(:parked)       # => false
    #   matcher.matches?(:first_gear)   # => true
    def matches?(value, _context = {})
      !values.include?(value)
    end

    # Finds all values that are *not* within the blacklist configured for this
    # matcher
    def filter(values)
      values - self.values
    end

    # A human-readable description of this matcher
    def description
      "all - #{values.length == 1 ? values.first.inspect : values.inspect}"
    end
  end

  # Matches a loopback of two values within a context.  Since there is no
  # configuration for this type of matcher, it must be used as a singleton.
  class LoopbackMatcher < Matcher
    include Singleton

    # Checks whether the given value matches what the value originally was.
    # This value should be defined in the context.
    #
    # == Examples
    #
    #   matcher = StateMachines::LoopbackMatcher.instance
    #   matcher.matches?(:parked, :from => :parked)   # => true
    #   matcher.matches?(:parked, :from => :idling)   # => false
    def matches?(value, context)
      context[:from] == value
    end

    # A human-readable description of this matcher.  Always "same".
    def description
      'same'
    end
  end
end
