# frozen_string_literal: true

require_relative 'options_validator'

module StateMachines
  # Represents a collection of transitions in a state machine
  class TransitionCollection < Array
    # Whether to skip running the action for each transition's machine
    attr_reader :skip_actions

    # Whether to skip running the after callbacks
    attr_reader :skip_after

    # Whether transitions should wrapped around a transaction block
    attr_reader :use_transactions

    # Options passed to the collection
    attr_reader :options

    # Creates a new collection of transitions that can be run in parallel.  Each
    # transition *must* be for a different attribute.
    #
    # Configuration options:
    # * <tt>:actions</tt> - Whether to run the action configured for each transition
    # * <tt>:after</tt> - Whether to run after callbacks
    # * <tt>:transaction</tt> - Whether to wrap transitions within a transaction
    def initialize(transitions = [], options = {})
      super(transitions)

      # Determine the validity of the transitions as a whole
      @valid = all?
      reject!(&:!)

      attributes = map(&:attribute).uniq
      raise ArgumentError, 'Cannot perform multiple transitions in parallel for the same state machine attribute' if attributes.length != length

      StateMachines::OptionsValidator.assert_valid_keys!(options, :actions, :after, :use_transactions)
      options = { actions: true, after: true, use_transactions: true }.merge(options)
      @skip_actions = !options[:actions]
      @skip_after = !options[:after]
      @use_transactions = options[:use_transactions]
      @options = options

      # Reset transitions when creating a new collection, except those a
      # preview run started, which this collection continues
      each do |transition|
        transition.reset unless transition.previewed?
      end
    end

    # Runs each of the collection's transitions in parallel.
    #
    # All transitions will run through the following steps:
    # 1. Before callbacks
    # 2. Persist state
    # 3. Invoke action
    # 4. After callbacks (if configured)
    # 5. Rollback (if action is unsuccessful)
    #
    # If a block is passed to this method, that block will be called instead
    # of invoking each transition's action.
    #
    # When the collection is refused, each transition that caused it carries
    # the reason in {StateMachines::Transition#refusal}, and the reason is
    # recorded for its event on the object.  The outcome of this attempt is
    # recorded however it ends: a success or an exception raised before any
    # outcome (e.g. by a callback) clears the reasons left by an earlier
    # attempt.
    #
    # When the action fails because an event attribute it performed was
    # refused (a collection nested inside the action, as the ORM integrations
    # run around save), the transitions carry that inner reason instead of
    # :action_failed.
    #
    # @return [Object, false] the action's result, or whether every transition
    #   succeeded
    # @see StateMachines::Event#refusal
    def perform(&)
      each { |transition| transition.refusal = nil }
      claims = TransitionClaim.claim(self) { |transition| transition.refusal = :contended }
      return false unless claims

      result = perform_transitions(&)
      assign_refusals unless success?
      result
    ensure
      record_refusals
      TransitionClaim.release(claims) if claims
    end

    class << self
      # Reports the reason an event attribute performed inside an action was
      # refused to the innermost collection running that action on the same
      # object, which then carries it instead of :action_failed if the action
      # fails.
      #
      # @api private
      # @param object [Object] the object the action runs on
      # @param reason [Symbol, nil] the inner refusal reason
      # @return [void]
      def report_nested_refusal(object, reason)
        return unless reason

        running = Thread.current[RUNNING_ACTIONS_KEY]&.reverse_each&.find { |collection| collection.object.equal?(object) }
        running&.nested_refusal ||= reason
      end
    end

    # The stack (Thread.current, so per fiber) of collections whose actions are running
    RUNNING_ACTIONS_KEY = :state_machines_running_actions

    # The reason an event attribute performed inside this collection's action
    # was refused (see .report_nested_refusal)
    #
    # @api private
    # @return [Symbol, nil]
    attr_accessor :nested_refusal

    # Gets the object being transitioned
    #
    # @return [Object]
    def object
      first.object
    end

    protected

    attr_reader :results # :nodoc:

    private

    def perform_transitions(&)
      reset

      if valid?
        if use_event_attributes? && !block_given?
          each do |transition|
            transition.transient = true
            transition.machine.write(object, :event_transition, transition)
          end

          @actions_run = true
          run_actions
        else
          within_transaction do
            catch(:halt) { run_callbacks(&) }
            rollback unless success?
          end
        end
      end

      if actions.length == 1 && results.include?(actions.first)
        results[actions.first]
      else
        success?
      end
    end

    # Is this a valid set of transitions?  If the collection was creating with
    # any +false+ values for transitions, then the the collection will be
    # marked as invalid.
    def valid?
      @valid
    end

    # Did each transition perform successfully?  This will only be true if the
    # following requirements are met:
    # * No +before+ callbacks halt
    # * All actions run successfully (always true if skipping actions)
    def success?
      @success
    end

    # Gets the list of actions to run.  If configured to skip actions, then
    # this will return an empty collection.
    def actions
      empty? ? [nil] : map(&:action).uniq
    end

    # Determines whether an event attribute be used to trigger the transitions
    # in this collection or whether the transitions be run directly *outside*
    # of the action.
    def use_event_attributes?
      !skip_actions && !skip_after && actions.all? && actions.length == 1 && first.machine.action_hook?
    end

    # Resets any information tracked from previous attempts to perform the
    # collection
    def reset
      @results = {}
      @success = false
      @actions_run = false
      @halted_by = nil
      @nested_refusal = nil
    end

    # Assigns the reason this collection was refused to the transitions that
    # caused it.  A reason already assigned by a collection nested inside the
    # action (an action hook performing the same transitions) is kept, since
    # it knows why the action failed; so is a reason reported by an event
    # attribute refused inside the action (see .report_nested_refusal).
    #
    # @return [void]
    def assign_refusals
      return if any?(&:refusal)

      if @actions_run
        reason = nested_refusal || :action_failed
        each { |transition| transition.refusal = reason }
      elsif @halted_by
        @halted_by.refusal = :halted
      end
    end

    # Records each transition's refusal (or its absence) for its event on the
    # object
    #
    # @return [void]
    # @see StateMachines::Event#record_refusal
    def record_refusals
      each { |transition| transition.machine.events.fetch(transition.event).record_refusal(transition.object, transition.refusal) }
    end

    # Runs each transition's callbacks recursively.  Once all before callbacks
    # have been executed, the transitions will then be persisted and the
    # configured actions will be run.
    #
    # If any transition fails to run its callbacks, :halt will be thrown.
    def run_callbacks(index = 0, &)
      if (transition = self[index])
        callback_result = transition.run_callbacks(after: !skip_after) do
          run_callbacks(index + 1, &)
          { result: results[transition.action], success: success? }
        end

        unless callback_result
          # The innermost transition to halt is the one that caused it; the
          # ones wrapping it halt as a consequence
          @halted_by ||= transition
          throw :halt
        end
      else
        persist
        @actions_run = true
        run_actions(&)
      end
    end

    # Transitions the current value of the object's states to those specified by
    # each transition
    def persist
      each(&:persist)
    end

    # Runs the actions for each transition.  If a block is given method, then it
    # will be called instead of invoking each transition's action.
    #
    # The results of the actions will be used to determine #success?.
    def run_actions
      catch_exceptions do
        @success = if block_given?
                     result = yield
                     actions.each { |action| results[action] = result }
                     !!result
                   else
                     actions.compact.each { |action| !skip_actions && (results[action] = object.send(action)) }
                     results.values.all?
                   end
      end
    end

    # Rolls back changes made to the object's states via each transition
    def rollback
      each(&:rollback)
    end

    # Wraps the given block with a rescue handler so that any exceptions that
    # occur will automatically result in the transition rolling back any changes
    # that were made to the object involved.
    #
    # An action that raises (e.g. ActiveRecord's save!) has failed, so the
    # transitions are refused with :action_failed before the exception
    # propagates.
    #
    # While the block runs, the collection is registered as running its
    # action on the object, so that event attributes refused inside it can
    # report their reason (see .report_nested_refusal).
    #
    # @raise [StandardError] whatever the block raised, after the rollback
    def catch_exceptions
      running = (Thread.current[RUNNING_ACTIONS_KEY] ||= [])
      running.push(self)
      begin
        yield
      ensure
        running.pop
      end
    rescue StandardError
      rollback
      each { |transition| transition.refusal ||= :action_failed }
      raise
    end

    # Runs a block within a transaction for the object being transitioned.  If
    # transactions are disabled, then this is a no-op.
    def within_transaction
      if use_transactions && !empty?
        first.within_transaction do
          yield
          success?
        end
      else
        yield
      end
    end
  end

  # Represents a collection of transitions that were generated from attribute-
  # based events
  class AttributeTransitionCollection < TransitionCollection
    def initialize(transitions = [], options = {}) # :nodoc:
      super(transitions, { use_transactions: false, actions: false }.merge(options))
    end

    # Performs the event attributes' transitions around the action.  When
    # they are refused, the reason is reported to the collection running the
    # action, if any (see TransitionCollection.report_nested_refusal).
    #
    # @return [Object, false] see TransitionCollection#perform
    def perform(&)
      result = super
      TransitionCollection.report_nested_refusal(object, find(&:refusal)&.refusal) unless empty? || success?
      result
    end

    private

    # Hooks into running transition callbacks so that event / event transition
    # attributes can be properly updated
    def run_callbacks(index = 0)
      if index.zero?
        # Clears any traces of the event attribute to prevent it from being
        # evaluated multiple times if actions are nested
        each do |transition|
          transition.machine.write(object, :event, nil)
          transition.machine.write(object, :event_transition, nil)
        end

        # Clear stored transitions hash for new cycle (issue #91)
        if !empty? && (obj = first.object)
          obj.instance_variable_set(:@_state_machine_event_transitions, nil)
        end

        # Rollback only if exceptions occur during before callbacks
        begin
          super
        rescue StandardError
          rollback unless @before_run
          @success = nil # mimics ActiveRecord.save behavior on rollback
          raise
        end

        # Persists transitions on the object if partial transition was successful.
        # This allows us to reference them later to complete the transition with
        # after callbacks.
        if skip_after && success?
          each { |transition| transition.machine.write(object, :event_transition, transition) }

          # Store transitions in a hash by machine name to avoid overwriting (issue #91)
          unless empty?
            transitions_by_machine = object.instance_variable_get(:@_state_machine_event_transitions) || {}
            each { |transition| transitions_by_machine[transition.machine.name] = transition }
            object.instance_variable_set(:@_state_machine_event_transitions, transitions_by_machine)
          end
        end

        # Complete any transitions that other machines generated mid-action
        # (e.g. an event attribute set in a before callback and picked up by
        # the validation cycle) so their after callbacks run in this same
        # action cycle instead of leaking into the next one (issue #91)
        complete_nested_transitions unless skip_after
      else
        super
      end
    end

    # Completes transitions that were stored for deferred completion by
    # machines outside this collection while the action was running.  Their
    # before callbacks and state persistence already happened mid-action;
    # only their after callbacks remain.  Clears the stored references so
    # they cannot leak into a later action cycle with stale data (issue #91).
    def complete_nested_transitions
      return if empty? || !success?

      pending = object.instance_variable_get(:@_state_machine_event_transitions)
      return unless pending

      machines = map(&:machine)
      pending.each_value do |transition|
        next if machines.include?(transition.machine)

        transition.machine.write(object, :event_transition, nil)
        transition.complete_deferred_after_callbacks
      end
      object.instance_variable_set(:@_state_machine_event_transitions, nil)
    end

    # Tracks that before callbacks have now completed
    def persist
      @before_run = true
      super
    end

    # Resets callback tracking
    def reset
      super
      @before_run = false
    end

    # Resets the event attribute so it can be re-evaluated if attempted again
    def rollback
      super
      each { |transition| transition.machine.write(object, :event, transition.event) unless transition.transient? }
    end
  end
end
