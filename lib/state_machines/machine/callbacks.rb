# frozen_string_literal: true

module StateMachines
  class Machine
    module Callbacks
      # Creates a callback that will be invoked *before* a transition is
      # performed so long as the given requirements match the transition.
      #
      # == The callback
      #
      # Callbacks must be defined as either an argument, in the :do option, or
      # as a block.  For example,
      #
      #   class Vehicle
      #     state_machine do
      #       before_transition :set_alarm
      #       before_transition :set_alarm, all => :parked
      #       before_transition all => :parked, :do => :set_alarm
      #       before_transition all => :parked do |vehicle, transition|
      #         vehicle.set_alarm
      #       end
      #       ...
      #     end
      #   end
      #
      # Notice that the first three callbacks are the same in terms of how the
      # methods to invoke are defined.  However, using the <tt>:do</tt> can
      # provide for a more fluid DSL.
      #
      # In addition, multiple callbacks can be defined like so:
      #
      #   class Vehicle
      #     state_machine do
      #       before_transition :set_alarm, :lock_doors, all => :parked
      #       before_transition all => :parked, :do => [:set_alarm, :lock_doors]
      #       before_transition :set_alarm do |vehicle, transition|
      #         vehicle.lock_doors
      #       end
      #     end
      #   end
      #
      # Notice that the different ways of configuring methods can be mixed.
      #
      # == State requirements
      #
      # Callbacks can require that the machine be transitioning from and to
      # specific states.  These requirements use a Hash syntax to map beginning
      # states to ending states.  For example,
      #
      #   before_transition :parked => :idling, :idling => :first_gear, :do => :set_alarm
      #
      # In this case, the +set_alarm+ callback will only be called if the machine
      # is transitioning from +parked+ to +idling+ or from +idling+ to +parked+.
      #
      # To help define state requirements, a set of helpers are available for
      # slightly more complex matching:
      # * <tt>all</tt> - Matches every state/event in the machine
      # * <tt>all - [:parked, :idling, ...]</tt> - Matches every state/event except those specified
      # * <tt>any</tt> - An alias for +all+ (matches every state/event in the machine)
      # * <tt>same</tt> - Matches the same state being transitioned from
      #
      # See StateMachines::MatcherHelpers for more information.
      #
      # Examples:
      #
      #   before_transition :parked => [:idling, :first_gear], :do => ...     # Matches from parked to idling or first_gear
      #   before_transition all - [:parked, :idling] => :idling, :do => ...   # Matches from every state except parked and idling to idling
      #   before_transition all => :parked, :do => ...                        # Matches all states to parked
      #   before_transition any => same, :do => ...                           # Matches every loopback
      #
      # == Event requirements
      #
      # In addition to state requirements, an event requirement can be defined so
      # that the callback is only invoked on specific events using the +on+
      # option.  This can also use the same matcher helpers as the state
      # requirements.
      #
      # Examples:
      #
      #   before_transition :on => :ignite, :do => ...                        # Matches only on ignite
      #   before_transition :on => all - :ignite, :do => ...                  # Matches on every event except ignite
      #   before_transition :parked => :idling, :on => :ignite, :do => ...    # Matches from parked to idling on ignite
      #
      # == Verbose Requirements
      #
      # Requirements can also be defined using verbose options rather than the
      # implicit Hash syntax and helper methods described above.
      #
      # Configuration options:
      # * <tt>:from</tt> - One or more states being transitioned from.  If none
      #   are specified, then all states will match.
      # * <tt>:to</tt> - One or more states being transitioned to.  If none are
      #   specified, then all states will match.
      # * <tt>:on</tt> - One or more events that fired the transition.  If none
      #   are specified, then all events will match.
      # * <tt>:except_from</tt> - One or more states *not* being transitioned from
      # * <tt>:except_to</tt> - One more states *not* being transitioned to
      # * <tt>:except_on</tt> - One or more events that *did not* fire the transition
      #
      # Examples:
      #
      #   before_transition :from => :ignite, :to => :idling, :on => :park, :do => ...
      #   before_transition :except_from => :ignite, :except_to => :idling, :except_on => :park, :do => ...
      #
      # == Conditions
      #
      # In addition to the state/event requirements, a condition can also be
      # defined to help determine whether the callback should be invoked.
      #
      # Configuration options:
      # * <tt>:if</tt> - A method, proc or string to call to determine if the
      #   callback should occur (e.g. :if => :allow_callbacks, or
      #   :if => lambda {|user| user.signup_step > 2}). The method, proc or string
      #   should return or evaluate to a true or false value.
      # * <tt>:unless</tt> - A method, proc or string to call to determine if the
      #   callback should not occur (e.g. :unless => :skip_callbacks, or
      #   :unless => lambda {|user| user.signup_step <= 2}). The method, proc or
      #   string should return or evaluate to a true or false value.
      #
      # Examples:
      #
      #   before_transition :parked => :idling, :if => :moving?, :do => ...
      #   before_transition :on => :ignite, :unless => :seatbelt_on?, :do => ...
      #
      # == Accessing the transition
      #
      # In addition to passing the object being transitioned, the actual
      # transition describing the context (e.g. event, from, to) can be accessed
      # as well.  This additional argument is only passed if the callback allows
      # for it.
      #
      # For example,
      #
      #   class Vehicle
      #     # Only specifies one parameter (the object being transitioned)
      #     before_transition all => :parked do |vehicle|
      #       vehicle.set_alarm
      #     end
      #
      #     # Specifies 2 parameters (object being transitioned and actual transition)
      #     before_transition all => :parked do |vehicle, transition|
      #       vehicle.set_alarm(transition)
      #     end
      #   end
      #
      # *Note* that the object in the callback will only be passed in as an
      # argument if callbacks are configured to *not* be bound to the object
      # involved.  This is the default and may change on a per-integration basis.
      #
      # See StateMachines::Transition for more information about the
      # attributes available on the transition.
      #
      # == Usage with delegates
      #
      # As noted above, state_machine uses the callback method's argument list
      # arity to determine whether to include the transition in the method call.
      # If you're using delegates, such as those defined in ActiveSupport or
      # Forwardable, the actual arity of the delegated method gets masked.  This
      # means that callbacks which reference delegates will always get passed the
      # transition as an argument.  For example:
      #
      #   class Vehicle
      #     extend Forwardable
      #     delegate :refresh => :dashboard
      #
      #     state_machine do
      #       before_transition :refresh
      #       ...
      #     end
      #
      #     def dashboard
      #       @dashboard ||= Dashboard.new
      #     end
      #   end
      #
      #   class Dashboard
      #     def refresh(transition)
      #       # ...
      #     end
      #   end
      #
      # In the above example, <tt>Dashboard#refresh</tt> *must* defined a
      # +transition+ argument.  Otherwise, an +ArgumentError+ exception will get
      # raised.  The only way around this is to avoid the use of delegates and
      # manually define the delegate method so that the correct arity is used.
      #
      # == Examples
      #
      # Below is an example of a class with one state machine and various types
      # of +before+ transitions defined for it:
      #
      #   class Vehicle
      #     state_machine do
      #       # Before all transitions
      #       before_transition :update_dashboard
      #
      #       # Before specific transition:
      #       before_transition [:first_gear, :idling] => :parked, :on => :park, :do => :take_off_seatbelt
      #
      #       # With conditional callback:
      #       before_transition all => :parked, :do => :take_off_seatbelt, :if => :seatbelt_on?
      #
      #       # Using helpers:
      #       before_transition all - :stalled => same, :on => any - :crash, :do => :update_dashboard
      #       ...
      #     end
      #   end
      #
      # As can be seen, any number of transitions can be created using various
      # combinations of configuration options.
      def before_transition(*args, **options, &)
        add_transition_callback(:before, args, options, &)
      end

      # Creates a callback that will be invoked *after* a transition is
      # performed so long as the given requirements match the transition.
      #
      # See +before_transition+ for a description of the possible configurations
      # for defining callbacks.
      def after_transition(*args, **options, &)
        add_transition_callback(:after, args, options, &)
      end

      # Creates a callback that will be invoked *around* a transition so long as
      # the given requirements match the transition.
      #
      # == The callback
      #
      # Around callbacks wrap transitions, executing code both before and after.
      # These callbacks are defined in the exact same manner as before / after
      # callbacks with the exception that the transition must be yielded to in
      # order to finish running it.
      #
      # If defining +around+ callbacks using blocks, you must yield within the
      # transition by directly calling the block (since yielding is not allowed
      # within blocks).
      #
      # For example,
      #
      #   class Vehicle
      #     state_machine do
      #       around_transition do |block|
      #         Benchmark.measure { block.call }
      #       end
      #
      #       around_transition do |vehicle, block|
      #         logger.info "vehicle was #{state}..."
      #         block.call
      #         logger.info "...and is now #{state}"
      #       end
      #
      #       around_transition do |vehicle, transition, block|
      #         logger.info "before #{transition.event}: #{vehicle.state}"
      #         block.call
      #         logger.info "after #{transition.event}: #{vehicle.state}"
      #       end
      #     end
      #   end
      #
      # Notice that referencing the block is similar to doing so within an
      # actual method definition in that it is always the last argument.
      #
      # On the other hand, if you're defining +around+ callbacks using method
      # references, you can yield like normal:
      #
      #   class Vehicle
      #     state_machine do
      #       around_transition :benchmark
      #       ...
      #     end
      #
      #     def benchmark
      #       Benchmark.measure { yield }
      #     end
      #   end
      #
      # See +before_transition+ for a description of the possible configurations
      # for defining callbacks.
      def around_transition(*args, **options, &)
        add_transition_callback(:around, args, options, &)
      end

      # Creates a callback that will be invoked *after* a transition failures to
      # be performed so long as the given requirements match the transition.
      #
      # See +before_transition+ for a description of the possible configurations
      # for defining callbacks.  *Note* however that you cannot define the state
      # requirements in these callbacks.  You may only define event requirements.
      #
      # = The callback
      #
      # Failure callbacks get invoked whenever an event fails to execute.  This
      # can happen when no transition is available, a +before+ callback halts
      # execution, or the action associated with this machine fails to succeed.
      # In any of these cases, any failure callback that matches the attempted
      # transition will be run.
      #
      # For example,
      #
      #   class Vehicle
      #     state_machine do
      #       after_failure do |vehicle, transition|
      #         logger.error "vehicle #{vehicle} failed to transition on #{transition.event}"
      #       end
      #
      #       after_failure :on => :ignite, :do => :log_ignition_failure
      #
      #       ...
      #     end
      #   end
      def after_failure(*args, **options, &)
        # Extract legacy positional arguments and merge with keyword options
        parsed_options = parse_callback_arguments(args, options)
        StateMachines::OptionsValidator.assert_valid_keys!(parsed_options, :on, :do, :if, :unless)

        add_callback(:failure, parsed_options, &)
      end

      private

      def add_transition_callback(type, args, options, &)
        # Extract legacy positional arguments and merge with keyword options
        parsed_options = parse_callback_arguments(args, options)

        # Only validate callback-specific options, not state transition requirements
        callback_options = parsed_options.slice(:do, :if, :unless, :bind_to_object, :terminator)
        StateMachines::OptionsValidator.assert_valid_keys!(callback_options, :do, :if, :unless, :bind_to_object, :terminator)

        add_callback(type, parsed_options, &)
      end
    end
  end
end
