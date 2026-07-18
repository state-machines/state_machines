# frozen_string_literal: true

require_relative 'options_validator'
require_relative 'machine/class_methods'
require_relative 'machine/utilities'
require_relative 'machine/parsing'
require_relative 'machine/validation'
require_relative 'machine/helper_generators'
require_relative 'machine/action_hooks'
require_relative 'machine/scoping'
require_relative 'machine/configuration'
require_relative 'machine/state_methods'
require_relative 'machine/event_methods'
require_relative 'machine/callbacks'
require_relative 'machine/rendering'
require_relative 'machine/integration'
require_relative 'machine/async_extensions'
require_relative 'syntax_validator'

module StateMachines
  # Represents a state machine for a particular attribute.  State machines
  # consist of states, events and a set of transitions that define how the
  # state changes after a particular event is fired.
  #
  # A state machine will not know all of the possible states for an object
  # unless they are referenced *somewhere* in the state machine definition.
  # As a result, any unused states should be defined with the +other_states+
  # or +state+ helper.
  #
  # == Actions
  #
  # When an action is configured for a state machine, it is invoked when an
  # object transitions via an event.  The success of the event becomes
  # dependent on the success of the action.  If the action is successful, then
  # the transitioned state remains persisted.  However, if the action fails
  # (by returning false), the transitioned state will be rolled back.
  #
  # For example,
  #
  #   class Vehicle
  #     attr_accessor :fail, :saving_state
  #
  #     state_machine :initial => :parked, :action => :save do
  #       event :ignite do
  #         transition :parked => :idling
  #       end
  #
  #       event :park do
  #         transition :idling => :parked
  #       end
  #     end
  #
  #     def save
  #       @saving_state = state
  #       fail != true
  #     end
  #   end
  #
  #   vehicle = Vehicle.new     # => #<Vehicle:0xb7c27024 @state="parked">
  #   vehicle.save              # => true
  #   vehicle.saving_state      # => "parked" # The state was "parked" was save was called
  #
  #   # Successful event
  #   vehicle.ignite            # => true
  #   vehicle.saving_state      # => "idling" # The state was "idling" when save was called
  #   vehicle.state             # => "idling"
  #
  #   # Failed event
  #   vehicle.fail = true
  #   vehicle.park              # => false
  #   vehicle.saving_state      # => "parked"
  #   vehicle.state             # => "idling"
  #
  # As shown, even though the state is set prior to calling the +save+ action
  # on the object, it will be rolled back to the original state if the action
  # fails.  *Note* that this will also be the case if an exception is raised
  # while calling the action.
  #
  # === Indirect transitions
  #
  # In addition to the action being run as the _result_ of an event, the action
  # can also be used to run events itself.  For example, using the above as an
  # example:
  #
  #   vehicle = Vehicle.new           # => #<Vehicle:0xb7c27024 @state="parked">
  #
  #   vehicle.state_event = 'ignite'
  #   vehicle.save                    # => true
  #   vehicle.state                   # => "idling"
  #   vehicle.state_event             # => nil
  #
  # As can be seen, the +save+ action automatically invokes the event stored in
  # the +state_event+ attribute (<tt>:ignite</tt> in this case).
  #
  # One important note about using this technique for running transitions is
  # that if the class in which the state machine is defined *also* defines the
  # action being invoked (and not a superclass), then it must manually run the
  # StateMachine hook that checks for event attributes.
  #
  # For example, in ActiveRecord, DataMapper, Mongoid, MongoMapper, and Sequel,
  # the default action (+save+) is already defined in a base class.  As a result,
  # when a state machine is defined in a model / resource, StateMachine can
  # automatically hook into the +save+ action.
  #
  # On the other hand, the Vehicle class from above defined its own +save+
  # method (and there is no +save+ method in its superclass).  As a result, it
  # must be modified like so:
  #
  #     def save
  #       self.class.state_machines.transitions(self, :save).perform do
  #         @saving_state = state
  #         fail != true
  #       end
  #     end
  #
  # This will add in the functionality for firing the event stored in the
  # +state_event+ attribute.
  #
  # == Callbacks
  #
  # Callbacks are supported for hooking before and after every possible
  # transition in the machine.  Each callback is invoked in the order in which
  # it was defined.  See StateMachines::Machine#before_transition and
  # StateMachines::Machine#after_transition for documentation on how to define
  # new callbacks.
  #
  # *Note* that callbacks only get executed within the context of an event.  As
  # a result, if a class has an initial state when it's created, any callbacks
  # that would normally get executed when the object enters that state will
  # *not* get triggered.
  #
  # For example,
  #
  #   class Vehicle
  #     state_machine initial: :parked do
  #       after_transition all => :parked do
  #         raise ArgumentError
  #       end
  #       ...
  #     end
  #   end
  #
  #   vehicle = Vehicle.new   # => #<Vehicle id: 1, state: "parked">
  #   vehicle.save            # => true (no exception raised)
  #
  # If you need callbacks to get triggered when an object is created, this
  # should be done by one of the following techniques:
  # * Use a <tt>before :create</tt> or equivalent hook:
  #
  #     class Vehicle
  #       before :create, :track_initial_transition
  #
  #       state_machine do
  #         ...
  #       end
  #     end
  #
  # * Set an initial state and use the correct event to create the
  #   object with the proper state, resulting in callbacks being triggered and
  #   the object getting persisted (note that the <tt>:pending</tt> state is
  #   actually stored as nil):
  #
  #     class Vehicle
  #        state_machine initial: :pending
  #         after_transition pending: :parked, do: :track_initial_transition
  #
  #         event :park do
  #           transition pending: :parked
  #         end
  #
  #         state :pending, value: nil
  #       end
  #     end
  #
  #     vehicle = Vehicle.new
  #     vehicle.park
  #
  # * Use a default event attribute that will automatically trigger when the
  #   configured action gets run (note that the <tt>:pending</tt> state is
  #   actually stored as nil):
  #
  #     class Vehicle < ActiveRecord::Base
  #       state_machine initial: :pending
  #         after_transition pending: :parked, do: :track_initial_transition
  #
  #         event :park do
  #           transition pending: :parked
  #         end
  #
  #         state :pending, value: nil
  #       end
  #
  #       def initialize(*)
  #         super
  #         self.state_event = 'park'
  #       end
  #     end
  #
  #     vehicle = Vehicle.new
  #     vehicle.save
  #
  # === Canceling callbacks
  #
  # Callbacks can be canceled by throwing :halt at any point during the
  # callback.  For example,
  #
  #   ...
  #   throw :halt
  #   ...
  #
  # If a +before+ callback halts the chain, the associated transition and all
  # later callbacks are canceled.  If an +after+ callback halts the chain,
  # the later callbacks are canceled, but the transition is still successful.
  #
  # These same rules apply to +around+ callbacks with the exception that any
  # +around+ callback that doesn't yield will essentially result in :halt being
  # thrown.  Any code executed after the yield will behave in the same way as
  # +after+ callbacks.
  #
  # *Note* that if a +before+ callback fails and the bang version of an event
  # was invoked, an exception will be raised instead of returning false.  For
  # example,
  #
  #   class Vehicle
  #     state_machine :initial => :parked do
  #       before_transition any => :idling, :do => lambda {|vehicle| throw :halt}
  #       ...
  #     end
  #   end
  #
  #   vehicle = Vehicle.new
  #   vehicle.park        # => false
  #   vehicle.park!       # => StateMachines::InvalidTransition: Cannot transition state via :park from "idling"
  #
  # == Observers
  #
  # Observers, in the sense of external classes and *not* Ruby's Observable
  # mechanism, can hook into state machines as well.  Such observers use the
  # same callback api that's used internally.
  #
  # Below are examples of defining observers for the following state machine:
  #
  #   class Vehicle
  #     state_machine do
  #       event :park do
  #         transition idling: :parked
  #       end
  #       ...
  #     end
  #     ...
  #   end
  #
  # Event/Transition behaviors:
  #
  #   class VehicleObserver
  #     def self.before_park(vehicle, transition)
  #       logger.info "#{vehicle} instructed to park... state is: #{transition.from}, state will be: #{transition.to}"
  #     end
  #
  #     def self.after_park(vehicle, transition, result)
  #       logger.info "#{vehicle} instructed to park... state was: #{transition.from}, state is: #{transition.to}"
  #     end
  #
  #     def self.before_transition(vehicle, transition)
  #       logger.info "#{vehicle} instructed to #{transition.event}... #{transition.attribute} is: #{transition.from}, #{transition.attribute} will be: #{transition.to}"
  #     end
  #
  #     def self.after_transition(vehicle, transition)
  #       logger.info "#{vehicle} instructed to #{transition.event}... #{transition.attribute} was: #{transition.from}, #{transition.attribute} is: #{transition.to}"
  #     end
  #
  #     def self.around_transition(vehicle, transition)
  #       logger.info Benchmark.measure { yield }
  #     end
  #   end
  #
  #   Vehicle.state_machine do
  #     before_transition :on => :park, :do => VehicleObserver.method(:before_park)
  #     before_transition VehicleObserver.method(:before_transition)
  #
  #     after_transition :on => :park, :do => VehicleObserver.method(:after_park)
  #     after_transition VehicleObserver.method(:after_transition)
  #
  #     around_transition VehicleObserver.method(:around_transition)
  #   end
  #
  # One common callback is to record transitions for all models in the system
  # for auditing/debugging purposes.  Below is an example of an observer that
  # can easily automate this process for all models:
  #
  #   class StateMachineObserver
  #     def self.before_transition(object, transition)
  #       Audit.log_transition(object.attributes)
  #     end
  #   end
  #
  #   [Vehicle, Switch, Project].each do |klass|
  #     klass.state_machines.each do |attribute, machine|
  #       machine.before_transition StateMachineObserver.method(:before_transition)
  #     end
  #   end
  #
  # Additional observer-like behavior may be exposed by the various integrations
  # available.  See below for more information on integrations.
  #
  # == Overriding instance / class methods
  #
  # Hooking in behavior to the generated instance / class methods from the
  # state machine, events, and states is very simple because of the way these
  # methods are generated on the class.  Using the class's ancestors, the
  # original generated method can be referred to via +super+.  For example,
  #
  #   class Vehicle
  #     state_machine do
  #       event :park do
  #         ...
  #       end
  #     end
  #
  #     def park(*args)
  #       logger.info "..."
  #       super
  #     end
  #   end
  #
  # In the above example, the +park+ instance method that's generated on the
  # Vehicle class (by the associated event) is overridden with custom behavior.
  # Once this behavior is complete, the original method from the state machine
  # is invoked by simply calling +super+.
  #
  # The same technique can be used for +state+, +state_name+, and all other
  # instance *and* class methods on the Vehicle class.
  #
  # == Method conflicts
  #
  # By default state_machine does not redefine methods that exist on
  # superclasses (*including* Object) or any modules (*including* Kernel) that
  # were included before it was defined.  This is in order to ensure that
  # existing behavior on the class is not broken by the inclusion of
  # state_machine.
  #
  # If a conflicting method is detected, state_machine will generate a warning.
  # For example, consider the following class:
  #
  #   class Vehicle
  #     state_machine do
  #       event :open do
  #         ...
  #       end
  #     end
  #   end
  #
  # In the above class, an event named "open" is defined for its state machine.
  # However, "open" is already defined as an instance method in Ruby's Kernel
  # module that gets included in every Object.  As a result, state_machine will
  # generate the following warning:
  #
  #   Instance method "open" is already defined in Object, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true. Defining :state state machine on Vehicle.
  #
  # Even though you may not be using Kernel's implementation of the "open"
  # instance method, state_machine isn't aware of this and, as a result, stays
  # safe and just skips redefining the method.
  #
  # As with almost all helpers methods defined by state_machine in your class,
  # there are generic methods available for working around this method conflict.
  # In the example above, you can invoke the "open" event like so:
  #
  #   vehicle = Vehicle.new       # => #<Vehicle:0xb72686b4 @state=nil>
  #   vehicle.fire_events(:open)  # => true
  #
  #   # This will not work
  #   vehicle.open                # => NoMethodError: private method `open' called for #<Vehicle:0xb72686b4 @state=nil>
  #
  # If you want to take on the risk of overriding existing methods and just
  # ignore method conflicts altogether, you can do so by setting the following
  # configuration:
  #
  #   StateMachines::Machine.ignore_method_conflicts = true
  #
  # This will allow you to define events like "open" as described above and
  # still generate the "open" instance helper method.  For example:
  #
  #   StateMachines::Machine.ignore_method_conflicts = true
  #
  #   class Vehicle
  #     state_machine do
  #       event :open do
  #         ...
  #     end
  #   end
  #
  #   vehicle = Vehicle.new   # => #<Vehicle:0xb72686b4 @state=nil>
  #   vehicle.open            # => true
  #
  # By default, state_machine helps prevent you from making mistakes and
  # accidentally overriding methods that you didn't intend to.  Once you
  # understand this and what the consequences are, setting the
  # +ignore_method_conflicts+ option is a perfectly reasonable workaround.
  #
  # == Integrations
  #
  # By default, state machines are library-agnostic, meaning that they work
  # on any Ruby class and have no external dependencies.  However, there are
  # certain libraries which expose additional behavior that can be taken
  # advantage of by state machines.
  #
  # This library is built to work out of the box with a few popular Ruby
  # libraries that allow for additional behavior to provide a cleaner and
  # smoother experience.  This is especially the case for objects backed by a
  # database that may allow for transactions, persistent storage,
  # search/filters, callbacks, etc.
  #
  # When a state machine is defined for classes using any of the above libraries,
  # it will try to automatically determine the integration to use (Agnostic,
  # ActiveModel, ActiveRecord, DataMapper, Mongoid, MongoMapper, or Sequel)
  # based on the class definition.  To see how each integration affects the
  # machine's behavior, refer to all constants defined under the
  # StateMachines::Integrations namespace.
  class Machine
    extend ClassMethods
    include EvalHelpers
    include MatcherHelpers
    include Utilities
    include Parsing
    include Validation
    include HelperGenerators
    include ActionHooks
    include Scoping
    include Configuration
    include StateMethods
    include EventMethods
    include Callbacks
    include Rendering
    include Integration

    # Whether to ignore any conflicts that are detected for helper methods that
    # get generated for a machine's owner class.  Default is false.
    # Thread-safe via atomic reference updates
    @ignore_method_conflicts = false

    # The class that the machine is defined in
    attr_reader :owner_class

    # The name of the machine, used for scoping methods generated for the
    # machine as a whole (not states or events)
    attr_reader :name

    # The events that trigger transitions.  These are sorted, by default, in
    # the order in which they were defined.
    attr_reader :events

    # A list of all of the states known to this state machine.  This will pull
    # states from the following sources:
    # * Initial state
    # * State behaviors
    # * Event transitions (:to, :from, and :except_from options)
    # * Transition callbacks (:to, :from, :except_to, and :except_from options)
    # * Unreferenced states (using +other_states+ helper)
    #
    # These are sorted, by default, in the order in which they were referenced.
    attr_reader :states

    # The callbacks to invoke before/after a transition is performed
    #
    # Maps :before => callbacks and :after => callbacks
    attr_reader :callbacks

    # The action to invoke when an object transitions
    attr_reader :action

    # An identifier that forces all methods (including state predicates and
    # event methods) to be generated with the value prefixed or suffixed,
    # depending on the context.
    attr_reader :namespace

    # Whether the machine will use transactions when firing events
    attr_reader :use_transactions

    # Defines a new helper method in an instance or class scope with the given
    # name.  If the method is already defined in the scope, then this will not
    # override it.
    #
    # If passing in a block, there are two side effects to be aware of
    # 1. The method cannot be chained, meaning that the block cannot call +super+
    # 2. If the method is already defined in an ancestor, then it will not get
    #    overridden and a warning will be output.
    #
    # Example:
    #
    #   # Instance helper
    #   machine.define_helper(:instance, :state_name) do |machine, object|
    #     machine.states.match(object).name
    #   end
    #
    #   # Class helper
    #   machine.define_helper(:class, :state_machine_name) do |machine, klass|
    #     "State"
    #   end
    #
    # You can also define helpers using string evaluation like so:
    #
    #   # Instance helper
    #   machine.define_helper :instance, <<-end_eval, __FILE__, __LINE__ + 1
    #     def state_name
    #       self.class.state_machine(:state).states.match(self).name
    #     end
    #   end_eval
    #
    #   # Class helper
    #   machine.define_helper :class, <<-end_eval, __FILE__, __LINE__ + 1
    #     def state_machine_name
    #       "State"
    #     end
    #   end_eval
    def define_helper(scope, method, *, **, &block)
      helper_module = @helper_modules.fetch(scope)

      if block_given?
        if !self.class.ignore_method_conflicts && (conflicting_ancestor = owner_class_ancestor_has_method?(scope, method))
          warn method_conflict_message(scope, method, conflicting_ancestor)
        else
          name = self.name
          helper_module.class_eval do
            define_method(method) do |*args, **kwargs|
              block.call((scope == :instance ? self.class : self).state_machine(name), self, *args, **kwargs)
            end
          end
        end
      else
        helper_module.class_eval(method, __FILE__, __LINE__)
      end
    end

    # Marks the given object as invalid with the given message.
    #
    # By default, this is a no-op.
    def invalidate(_object, _attribute, _message, _values = []); end

    # Gets a description of the errors for the given object.  This is used to
    # provide more detailed information when an InvalidTransition exception is
    # raised.
    def errors_for(_object)
      ''
    end

    # Resets any errors previously added when invalidating the given object.
    #
    # By default, this is a no-op.
    def reset(_object); end

    # Generates the message to use when invalidating the given object after
    # failing to transition on a specific event
    def generate_message(name, values = [])
      message = @messages[name] || self.class.default_messages[name]

      # Check whether there are actually any values to interpolate to avoid
      # any warnings
      if message.scan(/%./).any? { |match| match != '%%' }
        message % values.map(&:last)
      else
        message
      end
    end

    # Runs a transaction, rolling back any changes if the yielded block fails.
    #
    # This is only applicable to integrations that involve databases.  By
    # default, this will not run any transactions since the changes aren't
    # taking place within the context of a database.
    def within_transaction(object, &)
      if use_transactions
        transaction(object, &)
      else
        yield
      end
    end

    def renderer
      self.class.renderer
    end

    def draw(**)
      renderer.draw_machine(self, **)
    end

    # Determines whether an action hook was defined for firing attribute-based
    # event transitions when the configured action gets called.
    def action_hook?(self_only = false)
      @action_hook_defined || (!self_only && owner_class.state_machines.any? { |_name, machine| machine.action == action && machine != self && machine.action_hook?(true) })
    end

    protected

    # Runs additional initialization hooks.  By default, this is a no-op.
    def after_initialize; end

    # Always yields
    def transaction(_object)
      yield
    end

    # Gets the initial attribute value defined by the owner class (outside of
    # the machine's definition). By default, this is always nil.
    def owner_class_attribute_default
      nil
    end

    # Checks whether the given state matches the attribute default specified
    # by the owner class
    def owner_class_attribute_default_matches?(state)
      state.matches?(owner_class_attribute_default)
    end
  end
end
