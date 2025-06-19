# frozen_string_literal: true

module StateMachines
  class Machine
    module Utilities
      protected

      # Looks up other machines that have been defined in the owner class and
      # are targeting the same attribute as this machine.  When accessing
      # sibling machines, they will be automatically copied for the current
      # class if they haven't been already.  This ensures that any configuration
      # changes made to the sibling machines only affect this class and not any
      # base class that may have originally defined the machine.
      def sibling_machines
        owner_class.state_machines.each_with_object([]) do |(name, machine), machines|
          machines << (owner_class.state_machine(name) {}) if machine.attribute == attribute && machine != self
        end
      end

      # Looks up the ancestor class that has the given method defined.  This
      # is used to find the method owner which is used to determine where to
      # define new methods.
      def owner_class_ancestor_has_method?(scope, method)
        return false unless owner_class_has_method?(scope, method)

        superclasses = owner_class.ancestors.select { |ancestor| ancestor.is_a?(Class) }[1..]

        if scope == :class
          current = owner_class.singleton_class
          superclass = superclasses.first
        else
          current = owner_class
          superclass = owner_class.superclass
        end

        # Generate the list of modules that *only* occur in the owner class, but
        # were included *prior* to the helper modules, in addition to the
        # superclasses
        ancestors = current.ancestors - superclass.ancestors + superclasses
        helper_module_index = ancestors.index(@helper_modules[scope])
        ancestors = helper_module_index ? ancestors[helper_module_index..].reverse : ancestors.reverse

        # Search for for the first ancestor that defined this method
        ancestors.detect do |ancestor|
          ancestor = ancestor.singleton_class if scope == :class && ancestor.is_a?(Class)
          ancestor.method_defined?(method) || ancestor.private_method_defined?(method)
        end
      end

      # Determines whether the given method is defined in the owner class or
      # in a superclass.
      def owner_class_has_method?(scope, method)
        target = scope == :class ? owner_class.singleton_class : owner_class
        target.method_defined?(method) || target.private_method_defined?(method)
      end

      # Pluralizes the given word using #pluralize (if available) or simply
      # adding an "s" to the end of the word
      def pluralize(word)
        word = word.to_s
        if word.respond_to?(:pluralize)
          word.pluralize
        else
          "#{word}s"
        end
      end

      # Generates the results for the given scope based on one or more states to
      # filter by
      def run_scope(scope, machine, klass, states)
        values = states.flatten.compact.map { |state| machine.states.fetch(state).value }
        scope.call(klass, values)
      end

      # Adds sibling machine configurations to the current machine.  This
      # will add states from other machines that have the same attribute.
      def add_sibling_machine_configs
        # Add existing states
        sibling_machines.each do |machine|
          machine.states.each { |state| states << state unless states[state.name] }
        end
      end
    end
  end
end
