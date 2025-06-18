# frozen_string_literal: true

require 'test_helper'
require 'unit/eval_helper/eval_helpers_base_test'

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.2')

  class EvalHelpersSymbolTaintedMethodTest < EvalHelpersBaseTest
    def setup
      class << (@object = Object.new)
        def callback
          true
        end

        taint
      end
    end

    def test_should_not_raise_security_error
      evaluate_method(@object, :callback, 1, 2, 3)
    end
  end
end
