# frozen_string_literal: true

module StateMachines
  class Machine
    module Callbacks
      # Creates a callback that will be invoked *before* a transition is
      # performed so long as the given requirements match the transition.
      def before_transition(*args, **options, &)
        # Extract legacy positional arguments and merge with keyword options
        parsed_options = parse_callback_arguments(args, options)

        # Only validate callback-specific options, not state transition requirements
        callback_options = parsed_options.slice(:do, :if, :unless, :bind_to_object, :terminator)
        StateMachines::OptionsValidator.assert_valid_keys!(callback_options, :do, :if, :unless, :bind_to_object, :terminator)

        add_callback(:before, parsed_options, &)
      end

      # Creates a callback that will be invoked *after* a transition is
      # performed so long as the given requirements match the transition.
      def after_transition(*args, **options, &)
        # Extract legacy positional arguments and merge with keyword options
        parsed_options = parse_callback_arguments(args, options)

        # Only validate callback-specific options, not state transition requirements
        callback_options = parsed_options.slice(:do, :if, :unless, :bind_to_object, :terminator)
        StateMachines::OptionsValidator.assert_valid_keys!(callback_options, :do, :if, :unless, :bind_to_object, :terminator)

        add_callback(:after, parsed_options, &)
      end

      # Creates a callback that will be invoked *around* a transition so long
      # as the given requirements match the transition.
      def around_transition(*args, **options, &)
        # Extract legacy positional arguments and merge with keyword options
        parsed_options = parse_callback_arguments(args, options)

        # Only validate callback-specific options, not state transition requirements
        callback_options = parsed_options.slice(:do, :if, :unless, :bind_to_object, :terminator)
        StateMachines::OptionsValidator.assert_valid_keys!(callback_options, :do, :if, :unless, :bind_to_object, :terminator)

        add_callback(:around, parsed_options, &)
      end

      # Creates a callback that will be invoked after a transition has failed
      # to be performed.
      def after_failure(*args, **options, &)
        # Extract legacy positional arguments and merge with keyword options
        parsed_options = parse_callback_arguments(args, options)

        # Only validate callback-specific options, not state transition requirements
        callback_options = parsed_options.slice(:do, :if, :unless, :bind_to_object, :terminator)
        StateMachines::OptionsValidator.assert_valid_keys!(callback_options, :do, :if, :unless, :bind_to_object, :terminator)

        add_callback(:failure, parsed_options, &)
      end
    end
  end
end
