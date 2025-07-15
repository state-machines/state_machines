# frozen_string_literal: true

module StateMachines
  # A transition represents a state change for a specific attribute.
  #
  # Transitions consist of:
  # * An event
  # * A starting state
  # * An ending state
  class Transition
    # The object being transitioned
    attr_reader :object

    # The state machine for which this transition is defined
    attr_reader :machine

    # The original state value *before* the transition
    attr_reader :from

    # The new state value *after* the transition
    attr_reader :to

    # The arguments passed in to the event that triggered the transition
    # (does not include the +run_action+ boolean argument if specified)
    attr_accessor :args

    # The result of invoking the action associated with the machine
    attr_reader :result

    # Whether the transition is only existing temporarily for the object
    attr_writer :transient

    # Creates a new, specific transition
    def initialize(object, machine, event, from_name, to_name, read_state = true) # :nodoc:
      @object = object
      @machine = machine
      @args = []
      @transient = false
      @paused_fiber = nil
      @resuming = false
      @continuation_block = nil

      @event = machine.events.fetch(event)
      @from_state = machine.states.fetch(from_name)
      @from = read_state ? machine.read(object, :state) : @from_state.value
      @to_state = machine.states.fetch(to_name)
      @to = @to_state.value

      reset
    end

    # The attribute which this transition's machine is defined for
    def attribute
      machine.attribute
    end

    # The action that will be run when this transition is performed
    def action
      machine.action
    end

    # The event that triggered the transition
    def event
      @event.name
    end

    # The fully-qualified name of the event that triggered the transition
    def qualified_event
      @event.qualified_name
    end

    # The human-readable name of the event that triggered the transition
    def human_event
      @event.human_name(@object.class)
    end

    # The state name *before* the transition
    def from_name
      @from_state.name
    end

    # The fully-qualified state name *before* the transition
    def qualified_from_name
      @from_state.qualified_name
    end

    # The human-readable state name *before* the transition
    def human_from_name
      @from_state.human_name(@object.class)
    end

    # The new state name *after* the transition
    def to_name
      @to_state.name
    end

    # The new fully-qualified state name *after* the transition
    def qualified_to_name
      @to_state.qualified_name
    end

    # The new human-readable state name *after* the transition
    def human_to_name
      @to_state.human_name(@object.class)
    end

    # Does this transition represent a loopback (i.e. the from and to state
    # are the same)
    #
    # == Example
    #
    #   machine = StateMachine.new(Vehicle)
    #   StateMachines::Transition.new(Vehicle.new, machine, :park, :parked, :parked).loopback?   # => true
    #   StateMachines::Transition.new(Vehicle.new, machine, :park, :idling, :parked).loopback?   # => false
    def loopback?
      from_name == to_name
    end

    # Is this transition existing for a short period only?  If this is set, it
    # indicates that the transition (or the event backing it) should not be
    # written to the object if it fails.
    def transient?
      @transient
    end

    # A hash of all the core attributes defined for this transition with their
    # names as keys and values of the attributes as values.
    #
    # == Example
    #
    #   machine = StateMachine.new(Vehicle)
    #   transition = StateMachines::Transition.new(Vehicle.new, machine, :ignite, :parked, :idling)
    #   transition.attributes   # => {:object => #<Vehicle:0xb7d60ea4>, :attribute => :state, :event => :ignite, :from => 'parked', :to => 'idling'}
    def attributes
      @attributes ||= { object: object, attribute: attribute, event: event, from: from, to: to }
    end

    # Runs the actual transition and any before/after callbacks associated
    # with the transition.  The action associated with the transition/machine
    # can be skipped by passing in +false+.
    #
    # == Examples
    #
    #   class Vehicle
    #     state_machine :action => :save do
    #       ...
    #     end
    #   end
    #
    #   vehicle = Vehicle.new
    #   transition = StateMachines::Transition.new(vehicle, machine, :ignite, :parked, :idling)
    #   transition.perform                              # => Runs the +save+ action after setting the state attribute
    #   transition.perform(false)                       # => Only sets the state attribute
    #   transition.perform(run_action: false)           # => Only sets the state attribute
    #   transition.perform(Time.now)                    # => Passes in additional arguments and runs the +save+ action
    #   transition.perform(Time.now, false)             # => Passes in additional arguments and only sets the state attribute
    #   transition.perform(Time.now, run_action: false) # => Passes in additional arguments and only sets the state attribute
    def perform(*args)
      run_action = case args.last
                   in true | false
                     args.pop
                   in { run_action: }
                     args.last.delete(:run_action)
                   else
                     true
                   end

      self.args = args

      # Run the transition
      !!TransitionCollection.new([self], { use_transactions: machine.use_transactions, actions: run_action }).perform
    end

    # Runs a block within a transaction for the object being transitioned.
    # By default, transactions are a no-op unless otherwise defined by the
    # machine's integration.
    def within_transaction(&)
      machine.within_transaction(object, &)
    end

    # Runs the before / after callbacks for this transition.  If a block is
    # provided, then it will be executed between the before and after callbacks.
    #
    # Configuration options:
    # * +before+ - Whether to run before callbacks.
    # * +after+ - Whether to run after callbacks.  If false, then any around
    #   callbacks will be paused until called again with +after+ enabled.
    #   Default is true.
    #
    # This will return true if all before callbacks gets executed.  After
    # callbacks will not have an effect on the result.
    def run_callbacks(options = {}, &block)
      options = { before: true, after: true }.merge(options)

      # If we have a paused fiber and we're not trying to resume (after: false),
      # this is an idempotent call on an already-paused transition. Just return true.
      return true if @paused_fiber&.alive? && !options[:after]

      # Check if we're resuming from a pause
      if @paused_fiber&.alive? && options[:after]
        # Resume the paused fiber
        # Don't reset @success when resuming - preserve the state from the pause
        # Store the block for later execution
        @continuation_block = block if block_given?
        halted = pausable { true }
      else
        @success = false
        # For normal execution (not pause/resume), default to success
        # The action block will override this if needed
        halted = pausable { before(options[:after], &block) } if options[:before]
      end

      # After callbacks are only run if:
      # * An around callback didn't halt after yielding OR the run failed
      # * They're enabled or the run didn't succeed
      after if (!(@before_run && halted) || !@success) && (options[:after] || !@success)

      @before_run
    end

    # Transitions the current value of the state to that specified by the
    # transition.  Once the state is persisted, it cannot be persisted again
    # until this transition is reset.
    #
    # == Example
    #
    #   class Vehicle
    #     state_machine do
    #       event :ignite do
    #         transition :parked => :idling
    #       end
    #     end
    #   end
    #
    #   vehicle = Vehicle.new
    #   transition = StateMachines::Transition.new(vehicle, Vehicle.state_machine, :ignite, :parked, :idling)
    #   transition.persist
    #
    #   vehicle.state   # => 'idling'
    def persist
      return if @persisted

      machine.write(object, :state, to)
      @persisted = true
    end

    # Rolls back changes made to the object's state via this transition.  This
    # will revert the state back to the +from+ value.
    #
    # == Example
    #
    #   class Vehicle
    #     state_machine :initial => :parked do
    #       event :ignite do
    #         transition :parked => :idling
    #       end
    #     end
    #   end
    #
    #   vehicle = Vehicle.new     # => #<Vehicle:0xb7b7f568 @state="parked">
    #   transition = StateMachines::Transition.new(vehicle, Vehicle.state_machine, :ignite, :parked, :idling)
    #
    #   # Persist the new state
    #   vehicle.state             # => "parked"
    #   transition.persist
    #   vehicle.state             # => "idling"
    #
    #   # Roll back to the original state
    #   transition.rollback
    #   vehicle.state             # => "parked"
    def rollback
      reset
      machine.write(object, :state, from)
    end

    # Resets any tracking of which callbacks have already been run and whether
    # the state has already been persisted
    def reset
      @before_run = @persisted = @after_run = false
      @paused_fiber = nil
      @resuming = false
      @continuation_block = nil
    end

    # Determines equality of transitions by testing whether the object, states,
    # and event involved in the transition are equal
    def ==(other)
      other.instance_of?(self.class) &&
        other.object == object &&
        other.machine == machine &&
        other.from_name == from_name &&
        other.to_name == to_name &&
        other.event == event
    end

    # Generates a nicely formatted description of this transitions's contents.
    #
    # For example,
    #
    #   transition = StateMachines::Transition.new(object, machine, :ignite, :parked, :idling)
    #   transition   # => #<StateMachines::Transition attribute=:state event=:ignite from="parked" from_name=:parked to="idling" to_name=:idling>
    def inspect
      "#<#{self.class} #{%w[attribute event from from_name to to_name].map { |attr| "#{attr}=#{send(attr).inspect}" } * ' '}>"
    end

    # Checks whether this transition is currently paused.
    # Returns true if there is a paused fiber, false otherwise.
    def paused?
      @paused_fiber&.alive? || false
    end

    # Checks whether this transition has a paused fiber that can be resumed.
    # Returns true if there is a paused fiber, false otherwise.
    #
    # Note: The actual resuming happens automatically when run_callbacks is called
    # again on a transition with a paused fiber.
    def resumable?
      paused?
    end

    # Manually resumes the execution of a previously paused callback.
    # Returns true if the transition was successfully resumed and completed,
    # false if there was no paused fiber, and raises an exception if the
    # transition was halted.
    def resume!(&block)
      return false unless paused?

      # Store continuation block if provided
      @continuation_block = block if block_given?

      # Run the pausable block which will resume the fiber
      halted = pausable { true }

      # Return whether the transition completed successfully
      !halted
    end

    private

    # Runs a block that may get paused.  If the block doesn't pause, then
    # execution will continue as normal.  If the block gets paused, then it
    # will take care of switching the execution context when it's resumed.
    #
    # This will return true if the given block halts for a reason other than
    # getting paused.
    def pausable
      if @paused_fiber
        # Resume the paused fiber
        @resuming = true
        begin
          result = @paused_fiber.resume
        rescue StandardError => e
          # Clean up on exception
          @resuming = false
          @paused_fiber = nil
          raise e
        end
        @resuming = false

        # Handle different result types
        case result
        when Array
          # Exception occurred inside the fiber
          if result[0] == :error
            # Clean up state before re-raising
            @paused_fiber = nil
            raise result[1]
          end
        else
          # Normal flow
          # Check if fiber is still alive after resume
          if @paused_fiber.alive?
            # Still paused, keep the fiber
            true
          else
            # Fiber completed
            @paused_fiber = nil
            result == :halted
          end
        end
      else
        # Create a new fiber to run the block
        fiber = Fiber.new do
          halted = !catch(:halt) do
            yield
            true
          end
          halted ? :halted : :completed
        rescue StandardError => e
          # Store the exception for re-raising
          [:error, e]
        end

        # Run the fiber
        result = fiber.resume

        # Handle different result types
        case result
        when Array
          # Exception occurred
          if result[0] == :error
            # Clean up state before re-raising
            @paused_fiber = nil
            raise result[1]
          end
        else
          # Normal flow
          # Save if paused
          if fiber.alive?
            @paused_fiber = fiber
            # Return true to indicate paused (treated as halted for flow control)
            true
          else
            # Fiber completed, return whether it was halted
            result == :halted
          end
        end
      end
    end

    # Pauses the current callback execution.  This should only occur within
    # around callbacks when the remainder of the callback will be executed at
    # a later point in time.
    def pause
      # Don't pause if we're in the middle of resuming
      return if @resuming

      Fiber.yield

      # When we resume from the pause, execute the continuation block if present
      return unless @continuation_block && !@result

      action = { success: true }.merge(@continuation_block.call)
      @result = action[:result]
      @success = action[:success]
      @continuation_block = nil
    end

    # Runs the machine's +before+ callbacks for this transition.  Only
    # callbacks that are configured to match the event, from state, and to
    # state will be invoked.
    #
    # Once the callbacks are run, they cannot be run again until this transition
    # is reset.
    def before(complete = true, index = 0, &block)
      return if @before_run

      callback = machine.callbacks[:before][index]

      if callback
        # Check if callback matches this transition using branch
        if callback.branch.matches?(object, context)
          if callback.type == :around
            # Around callback: need to handle recursively.  Execution only gets
            # paused if:
            # * The block fails and the callback doesn't run on failures OR
            # * The block succeeds, but after callbacks are disabled (in which
            #   case a continuation is stored for later execution)
            callback.call(object, context, self) do
              before(complete, index + 1, &block)

              pause if @success && !complete

              # If the block failed (success is false), we should halt
              # the around callback from continuing
              throw :halt unless @success
            end
          else
            # Normal before callback
            callback.call(object, context, self)
            # Continue with next callback
            before(complete, index + 1, &block)
          end
        else
          # Skip to next callback if it doesn't match
          before(complete, index + 1, &block)
        end
      else
        # No more callbacks, execute the action block if at the end
        if block_given?
          action = { success: true }.merge(yield)
          @result = action[:result]
          @success = action[:success]
        else
          # No action block provided, default to success
          @success = true
        end

        @before_run = true
      end
    end

    # Runs the machine's +after+ callbacks for this transition.  Only
    # callbacks that are configured to match the event, from state, and to
    # state will be invoked.
    #
    # Once the callbacks are run, they cannot be run again until this transition
    # is reset.
    #
    # == Halting
    #
    # If any callback throws a <tt>:halt</tt> exception, it will be caught
    # and the callback chain will be automatically stopped.  However, this
    # exception will not bubble up to the caller since +after+ callbacks
    # should never halt the execution of a +perform+.
    def after
      return if @after_run

      catch(:halt) do
        type = @success ? :after : :failure
        machine.callbacks[type].each { |callback| callback.call(object, context, self) }
      end

      @after_run = true
    end

    # Gets a hash of the context defining this unique transition (including
    # event, from state, and to state).
    #
    # == Example
    #
    #   machine = StateMachine.new(Vehicle)
    #   transition = StateMachines::Transition.new(Vehicle.new, machine, :ignite, :parked, :idling)
    #   transition.context    # => {:on => :ignite, :from => :parked, :to => :idling}
    def context
      @context ||= { on: event, from: from_name, to: to_name }
    end
  end
end
