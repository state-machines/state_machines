# frozen_string_literal: true

module StateMachines
  class Machine
    module EventMethods
      # Defines one or more events for the machine and the transitions that can
      # be performed when those events are run.
      #
      # This method is also aliased as +on+ for improved compatibility with
      # using a domain-specific language.
      #
      # Configuration options:
      # * <tt>:human_name</tt> - The human-readable version of this event's name.
      #   By default, this is either defined by the integration or stringifies the
      #   name and converts underscores to spaces.
      #
      # == Instance methods
      #
      # The following instance methods are generated when a new event is defined
      # (the "park" event is used as an example):
      # * <tt>park(..., run_action = true)</tt> - Fires the "park" event,
      #   transitioning from the current state to the next valid state.  If the
      #   last argument is a boolean, it will control whether the machine's action
      #   gets run.
      # * <tt>park!(..., run_action = true)</tt> - Fires the "park" event,
      #   transitioning from the current state to the next valid state.  If the
      #   transition fails, then a StateMachines::InvalidTransition error will be
      #   raised.  If the last argument is a boolean, it will control whether the
      #   machine's action gets run.
      # * <tt>can_park?(requirements = {})</tt> - Checks whether the "park" event
      #   can be fired given the current state of the object.  This will *not* run
      #   validations or callbacks in ORM integrations.  It will only determine if
      #   the state machine defines a valid transition for the event.  To check
      #   whether an event can fire *and* passes validations, use event attributes
      #   (e.g. state_event) as described in the "Events" documentation of each
      #   ORM integration.
      # * <tt>park_transition(requirements = {})</tt> -  Gets the next transition
      #   that would be performed if the "park" event were to be fired now on the
      #   object or nil if no transitions can be performed.  Like <tt>can_park?</tt>
      #   this will also *not* run validations or callbacks.  It will only
      #   determine if the state machine defines a valid transition for the event.
      #
      # With a namespace of "car", the above names map to the following methods:
      # * <tt>can_park_car?</tt>
      # * <tt>park_car_transition</tt>
      # * <tt>park_car</tt>
      # * <tt>park_car!</tt>
      #
      # The <tt>can_park?</tt> and <tt>park_transition</tt> helpers both take an
      # optional set of requirements for determining what transitions are available
      # for the current object.  These requirements include:
      # * <tt>:from</tt> - One or more states to transition from.  If none are
      #   specified, then this will be the object's current state.
      # * <tt>:to</tt> - One or more states to transition to.  If none are
      #   specified, then this will match any to state.
      # * <tt>:guard</tt> - Whether to guard transitions with the if/unless
      #   conditionals defined for each one.  Default is true.
      #
      # == Defining transitions
      #
      # +event+ requires a block which allows you to define the possible
      # transitions that can happen as a result of that event.  For example,
      #
      #   event :park, :stop do
      #     transition :idling => :parked
      #   end
      #
      #   event :first_gear do
      #     transition :parked => :first_gear, :if => :seatbelt_on?
      #     transition :parked => same # Allow to loopback if seatbelt is off
      #   end
      #
      # See StateMachines::Event#transition for more information on
      # the possible options that can be passed in.
      #
      # *Note* that this block is executed within the context of the actual event
      # object.  As a result, you will not be able to reference any class methods
      # on the model without referencing the class itself.  For example,
      #
      #   class Vehicle
      #     def self.safe_states
      #       [:parked, :idling, :stalled]
      #     end
      #
      #     state_machine do
      #       event :park do
      #         transition Vehicle.safe_states => :parked
      #       end
      #     end
      #   end
      #
      # == Overriding the event method
      #
      # By default, this will define an instance method (with the same name as the
      # event) that will fire the next possible transition for that.  Although the
      # +before_transition+, +after_transition+, and +around_transition+ hooks
      # allow you to define behavior that gets executed as a result of the event's
      # transition, you can also override the event method in order to have a
      # little more fine-grained control.
      #
      # For example:
      #
      #   class Vehicle
      #     state_machine do
      #       event :park do
      #         ...
      #       end
      #     end
      #
      #     def park(*)
      #       take_deep_breath  # Executes before the transition (and before_transition hooks) even if no transition is possible
      #       if result = super # Runs the transition and all before/after/around hooks
      #         applaud         # Executes after the transition (and after_transition hooks)
      #       end
      #       result
      #     end
      #   end
      #
      # There are a few important things to note here.  First, the method
      # signature is defined with an unlimited argument list in order to allow
      # callers to continue passing arguments that are expected by state_machine.
      # For example, it will still allow calls to +park+ with a single parameter
      # for skipping the configured action.
      #
      # Second, the overridden event method must call +super+ in order to run the
      # logic for running the next possible transition.  In order to remain
      # consistent with other events, the result of +super+ is returned.
      #
      # Third, any behavior defined in this method will *not* get executed if
      # you're taking advantage of attribute-based event transitions.  For example:
      #
      #   vehicle = Vehicle.new
      #   vehicle.state_event = 'park'
      #   vehicle.save
      #
      # In this case, the +park+ event will run the before/after/around transition
      # hooks and transition the state, but the behavior defined in the overriden
      # +park+ method will *not* be executed.
      #
      # == Defining additional arguments
      #
      # Additional arguments can be passed into events and accessed by transition
      # hooks like so:
      #
      #   class Vehicle
      #     state_machine do
      #       after_transition :on => :park do |vehicle, transition|
      #         kind = *transition.args # :parallel
      #         ...
      #       end
      #       after_transition :on => :park, :do => :take_deep_breath
      #
      #       event :park do
      #         ...
      #       end
      #
      #       def take_deep_breath(transition)
      #         kind = *transition.args # :parallel
      #         ...
      #       end
      #     end
      #   end
      #
      #   vehicle = Vehicle.new
      #   vehicle.park(:parallel)
      #
      # *Remember* that if the last argument is a boolean, it will be used as the
      # +run_action+ parameter to the event action.  Using the +park+ action
      # example from above, you can might call it like so:
      #
      #   vehicle.park                    # => Uses default args and runs machine action
      #   vehicle.park(:parallel)         # => Specifies the +kind+ argument and runs the machine action
      #   vehicle.park(:parallel, false)  # => Specifies the +kind+ argument and *skips* the machine action
      #
      # If you decide to override the +park+ event method *and* define additional
      # arguments, you can do so as shown below:
      #
      #   class Vehicle
      #     state_machine do
      #       event :park do
      #         ...
      #       end
      #     end
      #
      #     def park(kind = :parallel, *args)
      #       take_deep_breath if kind == :parallel
      #       super
      #     end
      #   end
      #
      # Note that +super+ is called instead of <tt>super(*args)</tt>.  This allow
      # the entire arguments list to be accessed by transition callbacks through
      # StateMachines::Transition#args.
      #
      # === Using matchers
      #
      # The +all+ / +any+ matchers can be used to easily execute blocks for a
      # group of events.  Note, however, that you cannot use these matchers to
      # set configurations for events.  Blocks using these matchers can be
      # defined at any point in the state machine and will always get applied to
      # the proper events.
      #
      # For example:
      #
      #   state_machine :initial => :parked do
      #     ...
      #
      #     event all - [:crash] do
      #       transition :stalled => :parked
      #     end
      #   end
      #
      # == Example
      #
      #   class Vehicle
      #     state_machine do
      #       # The park, stop, and halt events will all share the given transitions
      #       event :park, :stop, :halt do
      #         transition [:idling, :backing_up] => :parked
      #       end
      #
      #       event :stop do
      #         transition :first_gear => :idling
      #       end
      #
      #       event :ignite do
      #         transition :parked => :idling
      #         transition :idling => same # Allow ignite while still idling
      #       end
      #     end
      #   end
      def event(*names, &)
        options = names.last.is_a?(Hash) ? names.pop : {}
        StateMachines::OptionsValidator.assert_valid_keys!(options, :human_name)

        # Store the context so that it can be used for / matched against any event
        # that gets added
        @events.context(names, &) if block_given?

        if names.first.is_a?(Matcher)
          # Add any events referenced in the matcher.  When matchers are used,
          # events are not allowed to be configured.
          raise ArgumentError, "Cannot configure events when using matchers (using #{options.inspect})" if options.any?

          events = add_events(names.first.values)
        else
          events = add_events(names)

          # Update the configuration for the event(s)
          events.each do |event|
            event.human_name = options[:human_name] if options.include?(:human_name)

            # Add any states that may have been referenced within the event
            add_states(event.known_states)
          end
        end

        events.length == 1 ? events.first : events
      end

      alias on event

      # Creates a new transition that determines what to change the current state
      # to when an event fires.
      #
      # == Defining transitions
      #
      # The options for a new transition uses the Hash syntax to map beginning
      # states to ending states.  For example,
      #
      #   transition :parked => :idling, :idling => :first_gear, :on => :ignite
      #
      # In this case, when the +ignite+ event is fired, this transition will cause
      # the state to be +idling+ if it's current state is +parked+ or +first_gear+
      # if it's current state is +idling+.
      #
      # To help define these implicit transitions, a set of helpers are available
      # for slightly more complex matching:
      # * <tt>all</tt> - Matches every state in the machine
      # * <tt>all - [:parked, :idling, ...]</tt> - Matches every state except those specified
      # * <tt>any</tt> - An alias for +all+ (matches every state in the machine)
      # * <tt>same</tt> - Matches the same state being transitioned from
      #
      # See StateMachines::MatcherHelpers for more information.
      #
      # Examples:
      #
      #   transition all => nil, :on => :ignite                               # Transitions to nil regardless of the current state
      #   transition all => :idling, :on => :ignite                           # Transitions to :idling regardless of the current state
      #   transition all - [:idling, :first_gear] => :idling, :on => :ignite  # Transitions every state but :idling and :first_gear to :idling
      #   transition nil => :idling, :on => :ignite                           # Transitions to :idling from the nil state
      #   transition :parked => :idling, :on => :ignite                       # Transitions to :idling if :parked
      #   transition [:parked, :stalled] => :idling, :on => :ignite           # Transitions to :idling if :parked or :stalled
      #
      #   transition :parked => same, :on => :park                            # Loops :parked back to :parked
      #   transition [:parked, :stalled] => same, :on => [:park, :stall]      # Loops either :parked or :stalled back to the same state on the park and stall events
      #   transition all - :parked => same, :on => :noop                      # Loops every state but :parked back to the same state
      #
      #   # Transitions to :idling if :parked, :first_gear if :idling, or :second_gear if :first_gear
      #   transition :parked => :idling, :idling => :first_gear, :first_gear => :second_gear, :on => :shift_up
      #
      # == Verbose transitions
      #
      # Transitions can also be defined use an explicit set of configuration
      # options:
      # * <tt>:from</tt> - A state or array of states that can be transitioned from.
      #   If not specified, then the transition can occur for *any* state.
      # * <tt>:to</tt> - The state that's being transitioned to.  If not specified,
      #   then the transition will simply loop back (i.e. the state will not change).
      # * <tt>:except_from</tt> - A state or array of states that *cannot* be
      #   transitioned from.
      #
      # These options must be used when defining transitions within the context
      # of a state.
      #
      # Examples:
      #
      #   transition :to => nil, :on => :park
      #   transition :to => :idling, :on => :ignite
      #   transition :except_from => [:idling, :first_gear], :to => :idling, :on => :ignite
      #   transition :from => nil, :to => :idling, :on => :ignite
      #   transition :from => [:parked, :stalled], :to => :idling, :on => :ignite
      #
      # == Conditions
      #
      # In addition to the state requirements for each transition, a condition
      # can also be defined to help determine whether that transition is
      # available.  These options will work on both the normal and verbose syntax.
      #
      # Configuration options:
      # * <tt>:if</tt> - A method, proc or string to call to determine if the
      #   transition should occur (e.g. :if => :moving?, or :if => lambda {|vehicle| vehicle.speed > 60}).
      #   The condition should return or evaluate to true or false.
      # * <tt>:unless</tt> - A method, proc or string to call to determine if the
      #   transition should not occur (e.g. :unless => :stopped?, or :unless => lambda {|vehicle| vehicle.speed <= 60}).
      #   The condition should return or evaluate to true or false.
      #
      # Examples:
      #
      #   transition :parked => :idling, :on => :ignite, :if => :moving?
      #   transition :parked => :idling, :on => :ignite, :unless => :stopped?
      #   transition :idling => :first_gear, :first_gear => :second_gear, :on => :shift_up, :if => :seatbelt_on?
      #
      #   transition :from => :parked, :to => :idling, :on => ignite, :if => :moving?
      #   transition :from => :parked, :to => :idling, :on => ignite, :unless => :stopped?
      #
      # == Order of operations
      #
      # Transitions are evaluated in the order in which they're defined.  As a
      # result, if more than one transition applies to a given object, then the
      # first transition that matches will be performed.
      def transition(options)
        raise ArgumentError, 'Must specify :on event' unless options[:on]

        branches = []
        options = options.dup
        event(*Array(options.delete(:on))) { branches << transition(options) }

        branches.length == 1 ? branches.first : branches
      end

      # Generates a list of the possible transition sequences that can be run on
      # the given object.  These paths can reveal all of the possible states and
      # events that can be encountered in the object's state machine based on the
      # object's current state.
      #
      # Configuration options:
      # * +from+ - The initial state to start all paths from.  By default, this
      #   is the object's current state.
      # * +to+ - The target state to end all paths on.  By default, paths will
      #   end when they loop back to the first transition on the path.
      # * +deep+ - Whether to allow the target state to be crossed more than once
      #   in a path.  By default, paths will immediately stop when the target
      #   state (if specified) is reached.  If this is enabled, then paths can
      #   continue even after reaching the target state; they will stop when
      #   reaching the target state a second time.
      #
      # *Note* that the object is never modified when the list of paths is
      # generated.
      #
      # == Examples
      #
      #   class Vehicle
      #     state_machine :initial => :parked do
      #       event :ignite do
      #         transition :parked => :idling
      #       end
      #
      #       event :shift_up do
      #         transition :idling => :first_gear, :first_gear => :second_gear
      #       end
      #
      #       event :shift_down do
      #         transition :second_gear => :first_gear, :first_gear => :idling
      #       end
      #     end
      #   end
      #
      #   vehicle = Vehicle.new   # => #<Vehicle:0xb7c27024 @state="parked">
      #   vehicle.state           # => "parked"
      #
      #   vehicle.state_paths
      #   # => [
      #   #     [#<StateMachines::Transition attribute=:state event=:ignite from="parked" from_name=:parked to="idling" to_name=:idling>,
      #   #      #<StateMachines::Transition attribute=:state event=:shift_up from="idling" from_name=:idling to="first_gear" to_name=:first_gear>,
      #   #      #<StateMachines::Transition attribute=:state event=:shift_up from="first_gear" from_name=:first_gear to="second_gear" to_name=:second_gear>,
      #   #      #<StateMachines::Transition attribute=:state event=:shift_down from="second_gear" from_name=:second_gear to="first_gear" to_name=:first_gear>,
      #   #      #<StateMachines::Transition attribute=:state event=:shift_down from="first_gear" from_name=:first_gear to="idling" to_name=:idling>],
      #   #
      #   #     [#<StateMachines::Transition attribute=:state event=:ignite from="parked" from_name=:parked to="idling" to_name=:idling>,
      #   #      #<StateMachines::Transition attribute=:state event=:shift_up from="idling" from_name=:idling to="first_gear" to_name=:first_gear>,
      #   #      #<StateMachines::Transition attribute=:state event=:shift_down from="first_gear" from_name=:first_gear to="idling" to_name=:idling>]
      #   #    ]
      #
      #   vehicle.state_paths(:from => :parked, :to => :second_gear)
      #   # => [
      #   #     [#<StateMachines::Transition attribute=:state event=:ignite from="parked" from_name=:parked to="idling" to_name=:idling>,
      #   #      #<StateMachines::Transition attribute=:state event=:shift_up from="idling" from_name=:idling to="first_gear" to_name=:first_gear>,
      #   #      #<StateMachines::Transition attribute=:state event=:shift_up from="first_gear" from_name=:first_gear to="second_gear" to_name=:second_gear>]
      #   #    ]
      #
      # In addition to getting the possible paths that can be accessed, you can
      # also get summary information about the states / events that can be
      # accessed at some point along one of the paths.  For example:
      #
      #   # Get the list of states that can be accessed from the current state
      #   vehicle.state_paths.to_states # => [:idling, :first_gear, :second_gear]
      #
      #   # Get the list of events that can be accessed from the current state
      #   vehicle.state_paths.events    # => [:ignite, :shift_up, :shift_down]
      def paths_for(object, requirements = {})
        PathCollection.new(object, self, requirements)
      end
    end
  end
end
