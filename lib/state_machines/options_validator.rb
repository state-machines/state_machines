# frozen_string_literal: true

module StateMachines
  # Define the module if it doesn't exist yet
  # Module for validating options without monkey-patching Hash
  # Provides the same functionality as the Hash monkey patch but in a cleaner way
  module OptionsValidator
    class << self
      # Validates that all keys in the options hash are in the list of valid keys
      #
      # @param options [Hash] The options hash to validate
      # @param valid_keys [Array<Symbol>] List of valid key names
      # @param caller_info [String] Information about the calling method for better error messages
      # @raise [ArgumentError] If any invalid keys are found
      def assert_valid_keys!(options, *valid_keys, caller_info: nil)
        return if options.empty?

        valid_keys.flatten!
        invalid_keys = options.keys - valid_keys

        return if invalid_keys.empty?

        caller_context = caller_info ? " in #{caller_info}" : ''
        raise ArgumentError, "Unknown key#{'s' if invalid_keys.length > 1}: #{invalid_keys.map(&:inspect).join(', ')}. Valid keys are: #{valid_keys.map(&:inspect).join(', ')}#{caller_context}"
      end

      # Validates that at most one of the exclusive keys is present in the options hash
      #
      # @param options [Hash] The options hash to validate
      # @param exclusive_keys [Array<Symbol>] List of mutually exclusive keys
      # @param caller_info [String] Information about the calling method for better error messages
      # @raise [ArgumentError] If more than one exclusive key is found
      def assert_exclusive_keys!(options, *exclusive_keys, caller_info: nil)
        return if options.empty?

        conflicting_keys = exclusive_keys & options.keys
        return if conflicting_keys.length <= 1

        caller_context = caller_info ? " in #{caller_info}" : ''
        raise ArgumentError, "Conflicting keys: #{conflicting_keys.join(', ')}#{caller_context}"
      end

      # Validates options using a more convenient interface that works with both
      # hash-style and kwargs-style method definitions
      #
      # @param valid_keys [Array<Symbol>] List of valid key names
      # @param exclusive_key_groups [Array<Array<Symbol>>] Groups of mutually exclusive keys
      # @param caller_info [String] Information about the calling method
      # @return [Proc] A validation proc that can be called with options
      def validator(valid_keys: [], exclusive_key_groups: [], caller_info: nil)
        proc do |options|
          assert_valid_keys!(options, *valid_keys, caller_info: caller_info) unless valid_keys.empty?

          exclusive_key_groups.each do |group|
            assert_exclusive_keys!(options, *group, caller_info: caller_info)
          end
        end
      end

      # Helper method for backwards compatibility - allows gradual migration
      # from Hash monkey patch to this module
      #
      # @param options [Hash] The options to validate
      # @param valid_keys [Array<Symbol>] Valid keys
      # @return [Hash] The same options hash (for chaining)
      def validate_and_return(options, *valid_keys)
        assert_valid_keys!(options, *valid_keys)
        options
      end
    end
  end
end
