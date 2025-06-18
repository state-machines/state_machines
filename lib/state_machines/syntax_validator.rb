# frozen_string_literal: true

require 'ripper'

module StateMachines
  # Cross-platform syntax validation for eval strings
  # Supports CRuby, JRuby, TruffleRuby via pluggable backends
  module SyntaxValidator
    # Public API: raises SyntaxError if code is invalid
    def validate!(code, filename = '(eval)')
      backend.validate!(code, filename)
    end
    module_function :validate!

    private

    # Lazily pick the best backend for this platform
    # Prefer RubyVM for performance on CRuby, fallback to Ripper for compatibility
    def backend
      @backend ||= if RubyVmBackend.available?
                     RubyVmBackend
                   else
                     RipperBackend
                   end
    end
    module_function :backend

    # MRI backend using RubyVM::InstructionSequence
    module RubyVmBackend
      def available?
        RUBY_ENGINE == 'ruby'
      end
      module_function :available?

      def validate!(code, filename)
        # compile will raise a SyntaxError on bad syntax
        RubyVM::InstructionSequence.compile(code, filename)
        true
      end
      module_function :validate!
    end

    # Universal Ruby backend via Ripper
    module RipperBackend
      def validate!(code, filename)
        sexp = Ripper.sexp(code)
        if sexp.nil?
          # Ripper.sexp returns nil on a parse error, but no exception
          raise SyntaxError, "syntax error in #{filename}"
        end
        true
      end
      module_function :validate!
    end
  end
end
