# frozen_string_literal: true

module StateMachines
  class Machine
    module StateMethods
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
      def initial_state(object)
        states.fetch(dynamic_initial_state? ? evaluate_method(object, @initial_state) : @initial_state) if instance_variable_defined?(:@initial_state)
      end

      # Whether a dynamic initial state is being used in the machine
      def dynamic_initial_state?
        instance_variable_defined?(:@initial_state) && @initial_state.is_a?(Proc)
      end

      # Initializes the state on the given object.  Initial values are only set if
      # the machine's attribute hasn't been previously initialized.
      #
      # Configuration options:
      # * <tt>:force</tt> - Whether to initialize the state regardless of its
      #   current value
      # * <tt>:to</tt> - A hash to set the initial value in instead of writing
      #   directly to the object
      def initialize_state(object, options = {})
        state = initial_state(object)
        return unless state && (options[:force] || initialize_state?(object))

        value = state.value

        if (hash = options[:to])
          hash[attribute.to_s] = value
        else
          write(object, :state, value)
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
      def state(*names, &)
        options = names.last.is_a?(Hash) ? names.pop : {}
        StateMachines::OptionsValidator.assert_valid_keys!(options, :value, :cache, :if, :human_name)

        # Store the context so that it can be used for / matched against any state
        # that gets added
        @states.context(names, &) if block_given?

        if names.first.is_a?(Matcher)
          # Add any states referenced in the matcher.  When matchers are used,
          # states are not allowed to be configured.
          raise ArgumentError, "Cannot configure states when using matchers (using #{options.inspect})" if options.any?

          states = add_states(names.first.values)
        else
          states = add_states(names)

          # Update the configuration for the state(s)
          states.each do |state|
            if options.include?(:value)
              state.value = options[:value]
              self.states.update(state)
            end

            state.human_name = options[:human_name] if options.include?(:human_name)
            state.cache = options[:cache] if options.include?(:cache)
            state.matcher = options[:if] if options.include?(:if)
          end
        end

        states.length == 1 ? states.first : states
      end

      alias other_states state

      # Gets the current value stored in the given object's attribute.
      def read(object, attribute, ivar = false)
        attribute = self.attribute(attribute)
        if ivar
          object.instance_variable_defined?(:"@#{attribute}") ? object.instance_variable_get("@#{attribute}") : nil
        else
          object.send(attribute)
        end
      end

      # Sets a new value in the given object's attribute.
      def write(object, attribute, value, ivar = false)
        attribute = self.attribute(attribute)
        ivar ? object.instance_variable_set(:"@#{attribute}", value) : object.send("#{attribute}=", value)
      end

      protected

      # Determines if the machine's attribute needs to be initialized.  This
      # will only be true if the machine's attribute is blank.
      def initialize_state?(object)
        value = read(object, :state)
        (value.nil? || (value.respond_to?(:empty?) && value.empty?)) && !states[value, :value]
      end
    end
  end
end
