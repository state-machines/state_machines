# frozen_string_literal: true

require_relative 'syntax_validator'

module StateMachines
  # Provides a set of helper methods for evaluating methods within the context
  # of an object.
  module EvalHelpers
    # Evaluates one of several different types of methods within the context
    # of the given object.  Methods can be one of the following types:
    # * Symbol
    # * Method / Proc
    # * String
    #
    # == Examples
    #
    # Below are examples of the various ways that a method can be evaluated
    # on an object:
    #
    #   class Person
    #     def initialize(name)
    #       @name = name
    #     end
    #
    #     def name
    #       @name
    #     end
    #   end
    #
    #   class PersonCallback
    #     def self.run(person)
    #       person.name
    #     end
    #   end
    #
    #   person = Person.new('John Smith')
    #
    #   evaluate_method(person, :name)                            # => "John Smith"
    #   evaluate_method(person, PersonCallback.method(:run))      # => "John Smith"
    #   evaluate_method(person, Proc.new {|person| person.name})  # => "John Smith"
    #   evaluate_method(person, lambda {|person| person.name})    # => "John Smith"
    #   evaluate_method(person, '@name')                          # => "John Smith"
    #
    # == Additional arguments
    #
    # Additional arguments can be passed to the methods being evaluated.  If
    # the method defines additional arguments other than the object context,
    # then all arguments are required.
    #
    # For guard conditions in state machines, event arguments can be passed
    # automatically based on the guard's arity:
    # - Guards with arity 1 receive only the object (backward compatible)
    # - Guards with arity -1 or > 1 receive object + event arguments
    #
    # For example,
    #
    #   person = Person.new('John Smith')
    #
    #   evaluate_method(person, lambda {|person| person.name}, 21)                              # => "John Smith"
    #   evaluate_method(person, lambda {|person, age| "#{person.name} is #{age}"}, 21)          # => "John Smith is 21"
    #   evaluate_method(person, lambda {|person, age| "#{person.name} is #{age}"}, 21, 'male')  # => ArgumentError: wrong number of arguments (3 for 2)
    #
    # With event arguments for guards:
    #
    #   # Single parameter guard (backward compatible)
    #   guard = lambda {|obj| obj.valid? }
    #   evaluate_method_with_event_args(object, guard, [arg1, arg2])  # => calls guard.call(object)
    #
    #   # Multi-parameter guard (receives event args)
    #   guard = lambda {|obj, *args| obj.valid? && args[0] == :force }
    #   evaluate_method_with_event_args(object, guard, [:force])      # => calls guard.call(object, :force)
    def evaluate_method(object, method, *args, **, &block)
      case method
      when Symbol
        klass = (class << object; self; end)
        args = [] if (klass.method_defined?(method) || klass.private_method_defined?(method)) && object.method(method).arity == 0
        object.send(method, *args, **, &block)
      when Proc
        args.unshift(object)
        arity = method.arity
        # Handle blocks for Procs
        if block_given? && arity != 0
          if [1, 2].include?(arity)
            # Force the block to be either the only argument or the second one
            # after the object (may mean additional arguments get discarded)
            args = args[0, arity - 1] + [block]
          else
            # insert the block to the end of the args
            args << block
          end
        elsif [0, 1].include?(arity)
          # These method types are only called with 0, 1, or n arguments
          args = args[0, arity]
        end

        # Call the Proc with the arguments
        method.call(*args, **)

      when Method
        args.unshift(object)
        arity = method.arity

        # Methods handle blocks via &block, not as arguments
        # Only limit arguments if necessary based on arity
        args = args[0, arity] if [0, 1].include?(arity)

        # Call the Method with the arguments and pass the block
        method.call(*args, **, &block)
      when String
        # Input validation for string evaluation
        validate_eval_string(method)

        if block_given?
          if StateMachines::Transition.pause_supported?
            eval(method, object.instance_eval { binding }, &block)
          else
            # Support for JRuby and Truffle Ruby, which don't support binding blocks
            # Need to check with @headius, if jruby 10 does now.
            eigen = class << object; self; end
            eigen.class_eval <<-RUBY, __FILE__, __LINE__ + 1
                  def __temp_eval_method__(*args, &b)
                    #{method}
                  end
            RUBY
            result = object.__temp_eval_method__(*args, &block)
            eigen.send(:remove_method, :__temp_eval_method__)
            result
          end
        else
          eval(method, object.instance_eval { binding })
        end
      else
        raise ArgumentError, 'Methods must be a symbol denoting the method to call, a block to be invoked, or a string to be evaluated'
      end
    end

    # Evaluates a guard method with support for event arguments passed to transitions.
    # This method uses arity detection to determine whether to pass event arguments
    # to the guard, ensuring backward compatibility.
    #
    # == Parameters
    # * object - The object context to evaluate within
    # * method - The guard method/proc to evaluate
    # * event_args - Array of arguments passed to the event (optional)
    #
    # == Arity-based behavior
    # * Arity 1: Only passes the object (backward compatible)
    # * Arity -1 or > 1: Passes object + event arguments
    #
    # == Examples
    #
    #   # Backward compatible single-parameter guard
    #   guard = lambda {|obj| obj.valid? }
    #   evaluate_method_with_event_args(object, guard, [:force])  # => calls guard.call(object)
    #
    #   # New multi-parameter guard receiving event args
    #   guard = lambda {|obj, *args| obj.valid? && args[0] != :skip }
    #   evaluate_method_with_event_args(object, guard, [:skip])   # => calls guard.call(object, :skip)
    def evaluate_method_with_event_args(object, method, event_args = [])
      case method
      when Symbol
        # Symbol methods currently don't support event arguments
        # This maintains backward compatibility
        evaluate_method(object, method)
      when Proc
        arity = method.arity

        # Arity-based decision for backward compatibility:
        # - arity 0: no arguments
        # - arity 1: only object (existing behavior)
        # - arity -1 (splat) or > 1: object + event args (new behavior)
        if arity == 0
          method.call
        elsif arity == 1
          method.call(object)
        elsif arity == -1
          # Splat parameters: object + all event args
          method.call(object, *event_args)
        elsif arity > 1
          # Explicit parameters: object + limited event args
          args_needed = arity - 1 # Subtract 1 for the object parameter
          method.call(object, *event_args[0, args_needed])
        else
          # Negative arity other than -1 (unlikely but handle gracefully)
          method.call(object, *event_args)
        end
      when Method
        arity = method.arity

        if arity == 0
          method.call
        elsif arity == 1
          method.call(object)
        elsif arity == -1
          method.call(object, *event_args)
        elsif arity > 1
          args_needed = arity - 1
          method.call(object, *event_args[0, args_needed])
        else
          method.call(object, *event_args)
        end
      when String
        # String evaluation doesn't support event arguments for security
        evaluate_method(object, method)
      else
        # Fall back to standard evaluation
        evaluate_method(object, method)
      end
    end

    private

    # Validates string input before eval to prevent code injection
    # This is a basic safety check - not foolproof security
    def validate_eval_string(method_string)
      # Check for obviously dangerous patterns
      dangerous_patterns = [
        /`.*`/,           # Backticks (shell execution)
        /system\s*\(/,    # System calls
        /exec\s*\(/,      # Exec calls
        /eval\s*\(/,      # Nested eval
        /require\s+['"]/, # Require statements
        /load\s+['"]/, # Load statements
        /File\./,         # File operations
        /IO\./,           # IO operations
        /Dir\./,          # Directory operations
        /Kernel\./        # Kernel operations
      ]

      dangerous_patterns.each do |pattern|
        raise SecurityError, "Potentially dangerous code detected in eval string: #{method_string.inspect}" if method_string.match?(pattern)
      end

      # Basic syntax validation - but allow yield since it's valid in block context
      begin
        test_code = method_string.include?('yield') ? "def dummy_method; #{method_string}; end" : method_string
        SyntaxValidator.validate!(test_code, '(eval)')
      rescue SyntaxError => e
        raise ArgumentError, "Invalid Ruby syntax in eval string: #{e.message}"
      end
    end
  end
end
