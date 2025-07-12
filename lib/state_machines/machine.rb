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
  #   Instance method "open" is already defined in Object, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.
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

    # Creates a new state machine for the given attribute

    # Gets the initial state of the machine for the given object. If a dynamic
    # initial state was configured for this machine, then the object will be
    # passed into the lambda block to help determine the actual state.
    #
    # == Examples
    #
    # With a static initial state:
    #
    #   class Vehicle
    #     state_machine :initial => :parked do
    #       ...
    #     end
    #   end
    #
    #   vehicle = Vehicle.new
    #   Vehicle.state_machine.initial_state(vehicle)  # => #<StateMachines::State name=:parked value="parked" initial=true>
    #
    # With a dynamic initial state:
    #
    #   class Vehicle
    #     attr_accessor :force_idle
    #
    #     state_machine :initial => lambda {|vehicle| vehicle.force_idle ? :idling : :parked} do
    #       ...
    #     end
    #   end
    #
    #   vehicle = Vehicle.new
    #
    #   vehicle.force_idle = true
    #   Vehicle.state_machine.initial_state(vehicle)  # => #<StateMachines::State name=:idling value="idling" initial=false>
    #
    #   vehicle.force_idle = false
    #   Vehicle.state_machine.initial_state(vehicle)  # => #<StateMachines::State name=:parked value="parked" initial=false>

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
          ancestor_name = conflicting_ancestor.name && !conflicting_ancestor.name.empty? ? conflicting_ancestor.name : conflicting_ancestor.to_s
          warn "#{scope == :class ? 'Class' : 'Instance'} method \"#{method}\" is already defined in #{ancestor_name}, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true."
        else
          name = self.name
          helper_module.class_eval do
            define_method(method) do |*args, **kwargs|
              block.call((scope == :instance ? self.class : self).state_machine(name), self, *args, **kwargs)
            end
          end
        end
      else
        # Validate string input before eval if method is a string
        validate_eval_string(method) if method.is_a?(String)
        helper_module.class_eval(method, __FILE__, __LINE__)
      end
    end

    # Customizes the definition of one or more states in the machine.
    #
    # Configuration options:
    # * <tt>:value</tt> - The actual value to store when an object transitions
    #   to the state.  Default is the name (stringified).
    # * <tt>:cache</tt> - If a dynamic value (via a lambda block) is being used,
    #   then setting this to true will cache the evaluated result
    # * <tt>:if</tt> - Determines whether an object's value matches the state
    #   (e.g. :value => lambda {Time.now}, :if => lambda {|state| !state.nil?}).
    #   By default, the configured value is matched.
    # * <tt>:human_name</tt> - The human-readable version of this state's name.
    #   By default, this is either defined by the integration or stringifies the
    #   name and converts underscores to spaces.
    #
    # == Customizing the stored value
    #
    # Whenever a state is automatically discovered in the state machine, its
    # default value is assumed to be the stringified version of the name.  For
    # example,
    #
    #   class Vehicle
    #     state_machine :initial => :parked do
    #       event :ignite do
    #         transition :parked => :idling
    #       end
    #     end
    #   end
    #
    # In the above state machine, there are two states automatically discovered:
    # :parked and :idling.  These states, by default, will store their stringified
    # equivalents when an object moves into that state (e.g. "parked" / "idling").
    #
    # For legacy systems or when tying state machines into existing frameworks,
    # it's oftentimes necessary to need to store a different value for a state
    # than the default.  In order to continue taking advantage of an expressive
    # state machine and helper methods, every defined state can be re-configured
    # with a custom stored value.  For example,
    #
    #   class Vehicle
    #     state_machine :initial => :parked do
    #       event :ignite do
    #         transition :parked => :idling
    #       end
    #
    #       state :idling, :value => 'IDLING'
    #       state :parked, :value => 'PARKED
    #     end
    #   end
    #
    # This is also useful if being used in association with a database and,
    # instead of storing the state name in a column, you want to store the
    # state's foreign key:
    #
    #   class VehicleState < ActiveRecord::Base
    #   end
    #
    #   class Vehicle < ActiveRecord::Base
    #     state_machine :attribute => :state_id, :initial => :parked do
    #       event :ignite do
    #         transition :parked => :idling
    #       end
    #
    #       states.each do |state|
    #         self.state(state.name, :value => lambda { VehicleState.find_by_name(state.name.to_s).id }, :cache => true)
    #       end
    #     end
    #   end
    #
    # In the above example, each known state is configured to store it's
    # associated database id in the +state_id+ attribute.  Also, notice that a
    # lambda block is used to define the state's value.  This is required in
    # situations (like testing) where the model is loaded without any existing
    # data (i.e. no VehicleState records available).
    #
    # One caveat to the above example is to keep performance in mind.  To avoid
    # constant db hits for looking up the VehicleState ids, the value is cached
    # by specifying the <tt>:cache</tt> option.  Alternatively, a custom
    # caching strategy can be used like so:
    #
    #   class VehicleState < ActiveRecord::Base
    #     cattr_accessor :cache_store
    #     self.cache_store = ActiveSupport::Cache::MemoryStore.new
    #
    #     def self.find_by_name(name)
    #       cache_store.fetch(name) { find(:first, :conditions => {:name => name}) }
    #     end
    #   end
    #
    # === Dynamic values
    #
    # In addition to customizing states with other value types, lambda blocks
    # can also be specified to allow for a state's value to be determined
    # dynamically at runtime.  For example,
    #
    #   class Vehicle
    #     state_machine :purchased_at, :initial => :available do
    #       event :purchase do
    #         transition all => :purchased
    #       end
    #
    #       event :restock do
    #         transition all => :available
    #       end
    #
    #       state :available, :value => nil
    #       state :purchased, :if => lambda {|value| !value.nil?}, :value => lambda {Time.now}
    #     end
    #   end
    #
    # In the above definition, the <tt>:purchased</tt> state is customized with
    # both a dynamic value *and* a value matcher.
    #
    # When an object transitions to the purchased state, the value's lambda
    # block will be called.  This will get the current time and store it in the
    # object's +purchased_at+ attribute.
    #
    # *Note* that the custom matcher is very important here.  Since there's no
    # way for the state machine to figure out an object's state when it's set to
    # a runtime value, it must be explicitly defined.  If the <tt>:if</tt> option
    # were not configured for the state, then an ArgumentError exception would
    # be raised at runtime, indicating that the state machine could not figure
    # out what the current state of the object was.
    #
    # == Behaviors
    #
    # Behaviors define a series of methods to mixin with objects when the current
    # state matches the given one(s).  This allows instance methods to behave
    # a specific way depending on what the value of the object's state is.
    #
    # For example,
    #
    #   class Vehicle
    #     attr_accessor :driver
    #     attr_accessor :passenger
    #
    #     state_machine :initial => :parked do
    #       event :ignite do
    #         transition :parked => :idling
    #       end
    #
    #       state :parked do
    #         def speed
    #           0
    #         end
    #
    #         def rotate_driver
    #           driver = self.driver
    #           self.driver = passenger
    #           self.passenger = driver
    #           true
    #         end
    #       end
    #
    #       state :idling, :first_gear do
    #         def speed
    #           20
    #         end
    #
    #         def rotate_driver
    #           self.state = 'parked'
    #           rotate_driver
    #         end
    #       end
    #
    #       other_states :backing_up
    #     end
    #   end
    #
    # In the above example, there are two dynamic behaviors defined for the
    # class:
    # * +speed+
    # * +rotate_driver+
    #
    # Each of these behaviors are instance methods on the Vehicle class.  However,
    # which method actually gets invoked is based on the current state of the
    # object.  Using the above class as the example:
    #
    #   vehicle = Vehicle.new
    #   vehicle.driver = 'John'
    #   vehicle.passenger = 'Jane'
    #
    #   # Behaviors in the "parked" state
    #   vehicle.state             # => "parked"
    #   vehicle.speed             # => 0
    #   vehicle.rotate_driver     # => true
    #   vehicle.driver            # => "Jane"
    #   vehicle.passenger         # => "John"
    #
    #   vehicle.ignite            # => true
    #
    #   # Behaviors in the "idling" state
    #   vehicle.state             # => "idling"
    #   vehicle.speed             # => 20
    #   vehicle.rotate_driver     # => true
    #   vehicle.driver            # => "John"
    #   vehicle.passenger         # => "Jane"
    #
    # As can be seen, both the +speed+ and +rotate_driver+ instance method
    # implementations changed how they behave based on what the current state
    # of the vehicle was.
    #
    # === Invalid behaviors
    #
    # If a specific behavior has not been defined for a state, then a
    # NoMethodError exception will be raised, indicating that that method would
    # not normally exist for an object with that state.
    #
    # Using the example from before:
    #
    #   vehicle = Vehicle.new
    #   vehicle.state = 'backing_up'
    #   vehicle.speed               # => NoMethodError: undefined method 'speed' for #<Vehicle:0xb7d296ac> in state "backing_up"
    #
    # === Using matchers
    #
    # The +all+ / +any+ matchers can be used to easily define behaviors for a
    # group of states.  Note, however, that you cannot use these matchers to
    # set configurations for states.  Behaviors using these matchers can be
    # defined at any point in the state machine and will always get applied to
    # the proper states.
    #
    # For example:
    #
    #   state_machine :initial => :parked do
    #     ...
    #
    #     state all - [:parked, :idling, :stalled] do
    #       validates_presence_of :speed
    #
    #       def speed
    #         gear * 10
    #       end
    #     end
    #   end
    #
    # == State-aware class methods
    #
    # In addition to defining scopes for instance methods that are state-aware,
    # the same can be done for certain types of class methods.
    #
    # Some libraries have support for class-level methods that only run certain
    # behaviors based on a conditions hash passed in.  For example:
    #
    #   class Vehicle < ActiveRecord::Base
    #     state_machine do
    #       ...
    #       state :first_gear, :second_gear, :third_gear do
    #         validates_presence_of   :speed
    #         validates_inclusion_of  :speed, :in => 0..25, :if => :in_school_zone?
    #       end
    #     end
    #   end
    #
    # In the above ActiveRecord model, two validations have been defined which
    # will *only* run when the Vehicle object is in one of the three states:
    # +first_gear+, +second_gear+, or +third_gear.  Notice, also, that if/unless
    # conditions can continue to be used.
    #
    # This functionality is not library-specific and can work for any class-level
    # method that is defined like so:
    #
    #   def validates_presence_of(attribute, options = {})
    #     ...
    #   end
    #
    # The minimum requirement is that the last argument in the method be an
    # options hash which contains at least <tt>:if</tt> condition support.

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
      # Extract legacy positional arguments and merge with keyword options
      parsed_options = parse_callback_arguments(args, options)

      # Only validate callback-specific options, not state transition requirements
      callback_options = parsed_options.slice(:do, :if, :unless, :bind_to_object, :terminator)
      StateMachines::OptionsValidator.assert_valid_keys!(callback_options, :do, :if, :unless, :bind_to_object, :terminator)

      add_callback(:before, parsed_options, &)
    end

    # Creates a callback that will be invoked *after* a transition is
    # performed so long as the given requirements match the transition.
    #
    # See +before_transition+ for a description of the possible configurations
    # for defining callbacks.
    def after_transition(*args, **options, &)
      # Extract legacy positional arguments and merge with keyword options
      parsed_options = parse_callback_arguments(args, options)

      # Only validate callback-specific options, not state transition requirements
      callback_options = parsed_options.slice(:do, :if, :unless, :bind_to_object, :terminator)
      StateMachines::OptionsValidator.assert_valid_keys!(callback_options, :do, :if, :unless, :bind_to_object, :terminator)

      add_callback(:after, parsed_options, &)
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
      # Extract legacy positional arguments and merge with keyword options
      parsed_options = parse_callback_arguments(args, options)

      # Only validate callback-specific options, not state transition requirements
      callback_options = parsed_options.slice(:do, :if, :unless, :bind_to_object, :terminator)
      StateMachines::OptionsValidator.assert_valid_keys!(callback_options, :do, :if, :unless, :bind_to_object, :terminator)

      add_callback(:around, parsed_options, &)
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

    # Determines whether there's already a helper method defined within the
    # given scope.  This is true only if one of the owner's ancestors defines
    # the method and is further along in the ancestor chain than this
    # machine's helper module.

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
