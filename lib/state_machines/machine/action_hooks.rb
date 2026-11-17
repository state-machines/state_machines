# frozen_string_literal: true

module StateMachines
  class Machine
    module ActionHooks
      protected

      # Determines whether action helpers should be defined for this machine.
      # This is only true if there is an action configured and no other machines
      # have process this same configuration already.
      def define_action_helpers?
        action && owner_class.state_machines.none? { |_name, machine| machine.action == action && machine != self }
      end

      # Adds helper methods for automatically firing events when an action
      # is invoked
      def define_action_helpers
        return unless action_hook

        @action_hook_defined = true
        define_action_hook
      end

      # Hooks directly into actions by defining the same method in an included
      # module.  As a result, when the action gets invoked, any state events
      # defined for the object will get run.  Method visibility is preserved.
      def define_action_hook
        action_hook = self.action_hook
        action = self.action
        # The hook replaces the action, so it keeps its exact visibility
        visibility = if owner_class.private_method_defined?(action_hook) then :private
                     elsif owner_class.protected_method_defined?(action_hook) then :protected
                     end

        # define_method, not a def in evaluated source: the action is a method
        # the owner already has, and Ruby allows names (:"save it") that no def
        # can spell
        helper = @helper_modules[:instance]
        helper.send(:define_method, action_hook) do |*args, **kwargs, &block|
          self.class.state_machines.transitions(self, action).perform { super(*args, **kwargs, &block) }
        end
        helper.send(visibility, action_hook) if visibility
      end

      # The method to hook into for triggering transitions when invoked.  By
      # default, this is the action configured for the machine.
      #
      # Since the default hook technique relies on module inheritance, the
      # action must be defined in an ancestor of the owner classs in order for
      # it to be the action hook.
      def action_hook
        action && owner_class_ancestor_has_method?(:instance, action) ? action : nil
      end
    end
  end
end
