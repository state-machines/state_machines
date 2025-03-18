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
    # For example,
    #
    #   person = Person.new('John Smith')
    #
    #   evaluate_method(person, lambda {|person| person.name}, 21)                              # => "John Smith"
    #   evaluate_method(person, lambda {|person, age| "#{person.name} is #{age}"}, 21)          # => "John Smith is 21"
    #   evaluate_method(person, lambda {|person, age| "#{person.name} is #{age}"}, 21, 'male')  # => ArgumentError: wrong number of arguments (3 for 2)
    def evaluate_method(object, method, *args, **kwargs, &block)
      case method
        when Symbol
          klass = (class << object; self; end)
          args = [] if (klass.method_defined?(method) || klass.private_method_defined?(method)) && object.method(method).arity == 0
          object.send(method, *args, **kwargs, &block)
        when Proc
          args.unshift(object)
          arity = method.arity
          # Handle blocks for Procs
          if block_given? && arity != 0
            if [1, 2].include?(arity)
              # Force the block to be either the only argument or the 2nd one
              # after the object (may mean additional arguments get discarded)
              args = args[0, arity - 1] + [block]
            else
              # Tack the block to the end of the args
              args << block
            end
          else
            # These method types are only called with 0, 1, or n arguments
            args = args[0, arity] if [0, 1].include?(arity)
          end

        # Call the Proc with the arguments
        method.call(*args, **kwargs)

        when Method
          args.unshift(object)
          arity = method.arity

          # Methods handle blocks via &block, not as arguments
          # Only limit arguments if necessary based on arity
          args = args[0, arity] if [0, 1].include?(arity)

          # Call the Method with the arguments and pass the block
          method.call(*args, **kwargs, &block)
        when String
          if block_given?
            if StateMachines::Transition.pause_supported?
              eval(method, object.instance_eval { binding }, &block)
            else
              # Support for JRuby and Truffle Ruby, which don't support binding blocks
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
  end
end
