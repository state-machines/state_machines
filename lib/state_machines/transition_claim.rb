# frozen_string_literal: true

module StateMachines
  # A hold on one of an object's machine attributes, granted for the duration
  # of a single TransitionCollection#perform
  class TransitionClaim
    # The authority a perform holds over the attributes it claimed.  The fibers
    # a perform spawns inherit its authority, which is retired once that
    # perform ends.
    class Owner
      def initialize
        @active = true
      end

      def active?
        @active
      end

      def retire
        @active = false
      end
    end

    CLAIMS_VARIABLE = :@_state_machine_transition_claims
    OWNER_KEY = :state_machines_transition_owner
    LOCK = Thread::Mutex.new

    class << self
      # Claims an attribute for every given transition whose machine runs in
      # async mode, ordered by attribute so that collections over the same
      # attributes claim them in the same order.
      #
      # Returns the granted claims, or nil when an attribute is held by another
      # active owner or has left the transition's source state.  Every exit
      # that does not grant the whole set - a refusal, an exception, a throw -
      # releases the claims it took.
      def claim(transitions)
        claimable = transitions.select { |transition| transition.machine.async_mode_enabled? }
        granted = []
        admitted = false

        begin
          admitted = claimable.sort_by { |transition| transition.attribute.to_s }.all? do |transition|
            hold(transition, granted) && at_source?(transition)
          end

          granted if admitted
        ensure
          release(granted) unless admitted
        end
      end

      # Releases the claims granted by .claim
      def release(claims)
        claims.reverse_each(&:release)
      end

      private

      # Takes the transition's attribute, appending the claim to +granted+ as it
      # is taken.  Returns nil when another active owner holds the attribute.
      def hold(transition, granted)
        previous_owner = Fiber[OWNER_KEY]
        owner = previous_owner&.active? ? previous_owner : Owner.new
        object = transition.object
        attribute = transition.attribute

        LOCK.synchronize do
          claims = claims_for(object)
          holder = claims[attribute]
          next unless holder.nil? || !holder.active? || holder.equal?(owner)

          claim = new(claims, attribute, owner, previous_owner, !holder.equal?(owner))
          granted << claim
          claims[attribute] = owner
          Fiber[OWNER_KEY] = owner
          claim
        end
      end

      def at_source?(transition)
        transition.machine.states.match!(transition.object).name == transition.from_name
      end

      def claims_for(object)
        object.instance_variable_get(CLAIMS_VARIABLE) || object.instance_variable_set(CLAIMS_VARIABLE, {})
      end
    end

    def initialize(claims, attribute, owner, previous_owner, held) # :nodoc:
      @claims = claims
      @attribute = attribute
      @owner = owner
      @previous_owner = previous_owner
      @held = held
    end

    # Gives up this claim, retiring its owner's authority when the claim
    # created it
    def release
      Fiber[OWNER_KEY] = @previous_owner

      LOCK.synchronize do
        @owner.retire unless @owner.equal?(@previous_owner)
        @claims.delete(@attribute) if @held
      end
    end
  end
end
