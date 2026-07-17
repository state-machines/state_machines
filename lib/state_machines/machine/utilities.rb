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

      # Determines whether there's already a helper method defined within the
      # given scope.  This is true only if one of the owner's ancestors defines
      # the method and is further along in the ancestor chain than this
      # machine's helper module.
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

      # Generates the warning message for a method conflict, including where
      # the conflicting method was defined (when it has a Ruby source
      # location) and which class the state machine is being defined on
      def method_conflict_message(scope, method, defined_in)
        scope_label = scope == :class ? 'Class' : 'Instance'
        defined_in_name = defined_in.name && !defined_in.name.empty? ? defined_in.name : defined_in.to_s
        location = conflicting_method_location(scope, method, defined_in)
        location_label = location ? " at #{location[0]}:#{location[1]}" : ''

        "#{scope_label} method \"#{method}\" is already defined in #{defined_in_name}#{location_label}, " \
          'use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true. ' \
          "Defining #{name.inspect} state machine on #{owner_class}."
      end

      # Looks up the source location of the conflicting method.  Returns nil
      # for methods without a Ruby source (e.g. C-defined methods like
      # Kernel#fail) and for the machine's own helper modules, where the
      # location would just point inside this gem
      def conflicting_method_location(scope, method, defined_in)
        return if @helper_modules.value?(defined_in)

        target = scope == :class && defined_in.is_a?(Class) ? defined_in.singleton_class : defined_in
        target.instance_method(method).source_location
      rescue NameError
        nil
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
