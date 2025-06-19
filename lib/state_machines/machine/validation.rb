# frozen_string_literal: true

module StateMachines
  class Machine
    module Validation
      # Frozen constant to avoid repeated array allocations
      DANGEROUS_PATTERNS = [
        /`.*`/,           # Backticks (shell execution)
        /system\s*\(/,    # System calls
        /exec\s*\(/,      # Exec calls
        /eval\s*\(/,      # Nested eval
        /require\s+['"]/, # Require statements
        /load\s+['"]/, # Load statements
        /File\./,         # File operations
        /IO\./,           # IO operations
        /Dir\./,          # Directory operations
        /Kernel\./        # Kernel operations
      ].freeze

      private

      # Validates string input before eval to prevent code injection
      # This is a basic safety check - not foolproof security
      def validate_eval_string(method_string)
        # Check for obviously dangerous patterns
        DANGEROUS_PATTERNS.each do |pattern|
          raise SecurityError, "Potentially dangerous code detected in eval string: #{method_string.inspect}" if method_string.match?(pattern)
        end

        # Basic syntax validation (cross-platform)
        begin
          SyntaxValidator.validate!(method_string, '(eval)')
        rescue SyntaxError => e
          raise ArgumentError, "Invalid Ruby syntax in eval string: #{e.message}"
        end
      end
    end
  end
end
