# frozen_string_literal: true

module StateMachines
  class Machine
    module Integration
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

      # Generates a user-friendly name for the given message.
      def generate_message(name, values = [])
        format(@messages[name] || @messages[:invalid_transition] || default_messages[name] || default_messages[:invalid_transition], state: values.first)
      end

      # Runs a transaction, yielding the given block.
      #
      # By default, this is a no-op.
      def within_transaction(object, &)
        if use_transactions && respond_to?(:transaction, true)
          transaction(object, &)
        else
          yield
        end
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

      private

      # Gets the default messages that can be used in the machine for invalid
      # transitions.
      def default_messages
        { invalid_transition: '%<state>s cannot transition via "%<event>s"' }
      end
    end
  end
end
