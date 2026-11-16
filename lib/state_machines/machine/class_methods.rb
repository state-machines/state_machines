# frozen_string_literal: true

module StateMachines
  class Machine
    module ClassMethods
      # Machine options that an extension gem provides, mapped to that gem.
      # A loaded extension consumes its option before the core validates the
      # options, so the core meeting one means the gem is not loaded.
      EXTENSION_OPTIONS = { async: 'state_machines-async' }.freeze

      # Attempts to find or create a state machine for the given class.  For
      # example,
      #
      #   StateMachines::Machine.find_or_create(Vehicle)
      #   StateMachines::Machine.find_or_create(Vehicle, :initial => :parked)
      #   StateMachines::Machine.find_or_create(Vehicle, :status)
      #   StateMachines::Machine.find_or_create(Vehicle, :status, :initial => :parked)
      #
      # If a machine of the given name already exists in one of the class's
      # superclasses, then a copy of that machine will be created and stored
      # in the new owner class (the original will remain unchanged).
      #
      # Reopening an existing machine applies the options in
      # Machine#reopen_options (+:initial+, plus any a loaded extension adds);
      # any other option raises ArgumentError instead of being ignored.
      def find_or_create(owner_class, *args, &)
        options = args.last.is_a?(Hash) ? args.pop : {}
        name = args.first || :state

        # Find an existing machine
        machine = (owner_class.respond_to?(:state_machines) &&
                  ((args.first && owner_class.state_machines[name]) || (!args.first &&
                  owner_class.state_machines.values.first))) || nil

        if machine
          reopenable = machine.reopen_options
          unsupported = options.keys - reopenable
          assert_extensions_loaded!(unsupported)
          unless unsupported.empty?
            raise ArgumentError, "Cannot change #{unsupported.map(&:inspect).join(', ')} of existing state machine " \
                                 "#{name.inspect} on #{owner_class}; reopening it accepts only #{reopenable.map(&:inspect).join(', ')}"
          end

          # Only create a new copy if changes are being made to the machine in
          # a subclass
          if machine.owner_class != owner_class && (options.any? || block_given?)
            machine = machine.clone
            machine.owner_class = owner_class
          end
          machine.reopen(options)

          # Evaluate DSL
          machine.instance_eval(&) if block_given?
        else
          # No existing machine: create a new one
          machine = new(owner_class, name, options, &)
        end

        machine
      end

      def draw(*)
        raise NotImplementedError
      end

      # Raises ArgumentError naming the gem when +keys+ holds an option of
      # EXTENSION_OPTIONS, whose gem is then not loaded, so that the option is
      # neither ignored nor reported as merely unknown.
      #
      # @api private
      # @param keys [Array<Symbol>] option names the core does not accept
      # @return [void]
      def assert_extensions_loaded!(keys)
        option = keys.find { |key| EXTENSION_OPTIONS.key?(key) }
        return unless option

        gem_name = EXTENSION_OPTIONS.fetch(option)
        raise ArgumentError, "The #{option.inspect} state machine option is provided by the #{gem_name} gem, " \
                             "which is not loaded; add it to your Gemfile and require '#{gem_name}'"
      end

      # Default messages to use for validation errors in ORM integrations
      # Thread-safe access via atomic operations on simple values
      attr_accessor :ignore_method_conflicts

      def default_messages
        @default_messages ||= {
          invalid: 'is invalid',
          invalid_event: 'cannot transition when %s',
          invalid_transition: 'cannot transition via "%1$s"'
        }.freeze
      end

      def default_messages=(messages)
        # Atomic replacement with frozen object
        @default_messages = deep_freeze_hash(messages)
      end

      def replace_messages(message_hash)
        # Atomic replacement: read current messages, merge with new ones, replace atomically
        current_messages = @default_messages || {}
        merged_messages = current_messages.merge(message_hash)
        @default_messages = deep_freeze_hash(merged_messages)
      end

      attr_writer :renderer

      def renderer
        return @renderer if @renderer

        STDIORenderer
      end

      private

      # Deep freezes a hash and all its string values for thread safety
      def deep_freeze_hash(hash)
        hash.each_with_object({}) do |(key, value), frozen_hash|
          frozen_key = key.respond_to?(:freeze) ? key.freeze : key
          frozen_value = value.respond_to?(:freeze) ? value.freeze : value
          frozen_hash[frozen_key] = frozen_value
        end.freeze
      end
    end
  end
end
