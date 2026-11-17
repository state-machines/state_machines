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

    # Why the most recent perform of this transition was refused.
    #
    # @return [:halted, :action_failed, :contended, nil] the refusal reason, or
    #   nil if the transition succeeded or was refused only because another
    #   transition in the same collection was
    # @see StateMachines::Event#refusal for the meaning of each reason
    attr_accessor :refusal

    # The event branch selected for this transition, whose before: / after: /
    # around: callbacks it runs; nil for a transition not built by an event
    attr_reader :branch

    # Creates a new, specific transition
    def initialize(object, machine, event, from_name, to_name, read_state = true, branch: nil) # :nodoc:
      @object = object
      @machine = machine
      @branch = branch
      @args = []
      @transient = false

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
    #
    # @return [StateMachines::Transition, false] this transition when it
    #   succeeds, false when it is refused (see {#refusal})
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
      TransitionCollection.new([self], { use_transactions: machine.use_transactions, actions: run_action }).perform ? self : false
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
    # * +after+ - Whether to run after callbacks.  If false (and +before+ is
    #   enabled), the run is a preview (e.g. validating before a save): every
    #   before callback runs, the around callbacks are skipped (not entered,
    #   their conditions not evaluated), then the block, and no after
    #   callbacks (failure callbacks if it halts or the block fails).  The
    #   next run with +after+ enabled does not repeat those before callbacks;
    #   its around callbacks wrap only its action.  So after a preview, a
    #   before callback declared after an around callback has run outside
    #   that around; without a preview, callbacks interleave as declared.
    #   Default is true.
    #
    # This will return true if all before callbacks gets executed.  After
    # callbacks will not have an effect on the result.
    def run_callbacks(options = {}, &)
      options = { before: true, after: true }.merge(options)
      return preview(&) if options[:before] && !options[:after]

      if options[:before]
        @success = false
        halted = !catch(:halt) do
          before(&)
          true
        end
        # The full run consumed any preview: the transition is now like one
        # never previewed (a collection resets it before running it again)
        @previewed = nil
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
      @before_callbacks = nil
      @previewed = nil
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

    # Whether a preview run (run_callbacks with after: false) has run part of
    # this transition's before chain, which the next full run continues
    def previewed?
      !@previewed.nil?
    end

    # Completes a transition whose before phase has already run by executing
    # its after callbacks, running any around callbacks its preview left first.  Used
    # to finish transitions that were stored for deferred completion (e.g.
    # generated mid-action from an event attribute) once their action has
    # succeeded.
    def complete_deferred_after_callbacks
      if previewed?
        run_callbacks(after: true)
      else
        after
      end
    end

    private

    # A preview run: every before callback not run by an earlier preview,
    # skipping the around callbacks (not entered, nor their conditions
    # evaluated: they wrap the action of the full run), then the block; on a
    # halt or a failed block, the failure callbacks.  Running all the befores
    # lets a validation in the block see what the full run's befores set, so
    # it agrees with the full run.  Returns false if it halted, including a
    # halt from the block.
    def preview # rubocop:disable Naming/PredicateMethod -- returns whether the befores ran, as run_callbacks does
      @previewed ||= {}.compare_by_identity
      halted = !catch(:halt) do
        before_callbacks.each do |callback|
          next if callback.type == :around || @previewed.key?(callback)

          # Recorded before running, so a halting callback is not run again
          @previewed[callback] = true
          callback.call(object, context, self)
        end

        # Inside the catch, as in a full run: the block (e.g. the collection
        # running the next machine's transition) may halt, which fails this
        # transition too
        action = block_given? ? { success: true }.merge(yield) : { success: true }
        @result = action[:result]
        @success = action[:success]
        true
      end
      @success = false if halted

      # A preview that halts or fails is a failed transition: its failure
      # callbacks run, as in a full run (after callbacks only follow success)
      after unless @success
      !halted
    end

    # Runs the machine's +before+ callbacks for this transition.  Only
    # callbacks that are configured to match the event, from state, and to
    # state will be invoked.
    #
    # Once the callbacks are run, they cannot be run again until this transition
    # is reset.
    def before(index = 0, &)
      return if @before_run

      callback = before_callbacks[index]

      if callback
        # Callback#call evaluates the callback's conditions (once) and answers
        # whether it applied
        if callback.type == :around
          # The rest of the chain, and the action, run inside the around
          applied = callback.call(object, context, self) do
            before(index + 1, &)

            # If the block failed (success is false), we should halt
            # the around callback from continuing
            throw :halt unless @success
          end
          before(index + 1, &) unless applied
        else
          # A preview already ran this before callback
          callback.call(object, context, self) unless @previewed&.key?(callback)
          before(index + 1, &)
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
        # A branch's afters run before the machine's, closest to the change;
        # they run on success only (a branch has no after_failure)
        callbacks = @success ? branch_callbacks(:after) + machine.callbacks[:after] : machine.callbacks[:failure]
        callbacks.each { |callback| callback.call(object, context, self) }
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

    # The before chain: the machine's before / around callbacks, then the
    # selected branch's, so branch callbacks wrap closest to the state change.
    # It is taken once per run: a callback registered while the chain runs
    # (e.g. from inside a before_transition) applies from the next transition,
    # not to the one in progress, whose chain cannot change under it.
    def before_callbacks
      @before_callbacks ||= machine.callbacks[:before] + branch_callbacks(:before, :around)
    end

    def branch_callbacks(*types)
      return [] unless branch

      branch.callbacks.select { |callback| types.include?(callback.type) }
    end
  end
end
