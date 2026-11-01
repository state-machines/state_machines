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
      # active owner or has left the transition's source state, in which case
      # the claims already granted are released.
      def claim(transitions)
        claimable = transitions.select { |transition| transition.machine.async_mode_enabled? }
        granted = []

        claimable.sort_by { |transition| transition.attribute.to_s }.each do |transition|
          claim = claim_attribute(transition)
          break unless claim

          granted << claim
        end

        return granted if granted.length == claimable.length

        release(granted)
        nil
      end

      # Releases the claims granted by .claim
      def release(claims)
        claims.reverse_each(&:release)
      end

      private

      def claim_attribute(transition)
        previous_owner = Fiber[OWNER_KEY]
        claims = claims_for(transition.object)

        claim = LOCK.synchronize do
          owner = previous_owner&.active? ? previous_owner : Owner.new
          holder = claims[transition.attribute]

          if holder.equal?(owner)
            new(claims, transition.attribute, owner, previous_owner, false)
          elsif (holder.nil? || !holder.active?) && transition.machine.states.match!(transition.object).name == transition.from_name
            claims[transition.attribute] = owner
            new(claims, transition.attribute, owner, previous_owner, true)
          end
        end

        Fiber[OWNER_KEY] = claim.owner if claim
        claim
      end

      def claims_for(object)
        object.instance_variable_get(CLAIMS_VARIABLE) || object.instance_variable_set(CLAIMS_VARIABLE, {})
      end
    end

    # The authority this claim was granted to
    attr_reader :owner

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
