# frozen_string_literal: true

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
    # Prefer RubyVM for performance on CRuby, fallback to eval for compatibility
    def backend
      @backend ||= if RubyVmBackend.available?
                     RubyVmBackend
                   else
                     UniversalBackend
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

    # Universal Ruby backend
    module UniversalBackend
      def validate!(code, filename)
        code = code.b
        code.sub!(/\A(?:\xef\xbb\xbf)?(\s*\#.*$)*(\n)?/n) {
          "#$&#{"\n" if $1 && !$2}BEGIN{throw tag, :ok}\n"
        }
        code = code.force_encoding(Encoding::UTF_8)
        catch { |tag| eval(code, binding, filename, __LINE__ - 1) } == :ok
      end
      module_function :validate!
    end
  end
end
