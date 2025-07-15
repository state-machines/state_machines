# frozen_string_literal: true

require_relative '../../test_helper'

class EvalHelpersWithEventArgumentsTest < StateMachinesTest
  include StateMachines::EvalHelpers

  def setup
    @object = Object.new
    @object.instance_variable_set(:@value, 'test')
    def @object.value
      @value
    end

    def @object.valid?
      true
    end
  end

  def test_single_parameter_proc_only_receives_object
    proc = ->(obj) { obj.valid? }

    # Should call with only object, ignoring event args
    assert evaluate_method_with_event_args(@object, proc, %i[arg1 arg2])
  end

  def test_splat_parameter_proc_receives_object_and_event_args
    result_args = nil
    proc = lambda { |obj, *args|
      result_args = args
      obj.valid?
    }

    # Should call with object + event args
    assert evaluate_method_with_event_args(@object, proc, %i[arg1 arg2])
    assert_equal %i[arg1 arg2], result_args
  end

  def test_explicit_multiple_parameter_proc_receives_object_and_event_args
    result_obj = nil
    result_arg1 = nil
    result_arg2 = nil
    proc = lambda { |obj, arg1, arg2|
      result_obj = obj
      result_arg1 = arg1
      result_arg2 = arg2
      true
    }

    # Should call with object + first two event args
    assert evaluate_method_with_event_args(@object, proc, %i[first second third])
    assert_equal @object, result_obj
    assert_equal :first, result_arg1
    assert_equal :second, result_arg2
  end

  def test_zero_parameter_proc_receives_no_arguments
    called = false
    proc = lambda {
      called = true
      true
    }

    # Should call with no arguments
    assert evaluate_method_with_event_args(@object, proc, %i[arg1 arg2])
    assert called
  end

  def test_symbol_method_ignores_event_args
    # Symbol methods should work normally, ignoring event args
    assert evaluate_method_with_event_args(@object, :valid?, %i[any args])
  end

  def test_string_method_ignores_event_args
    # String methods should work normally, ignoring event args
    assert evaluate_method_with_event_args(@object, '@value == "test"', %i[any args])
  end

  def test_method_object_with_single_arity
    method = @object.method(:valid?)

    # Should call with only object for arity 0 methods
    assert evaluate_method_with_event_args(@object, method, %i[arg1 arg2])
  end

  def test_method_object_with_multiple_arity
    # Create a method that accepts multiple arguments
    def @object.check_args(obj, arg1, arg2)
      obj == self && arg1 == :first && arg2 == :second
    end

    method = @object.method(:check_args)

    # Should call with event args for multi-arity methods
    assert evaluate_method_with_event_args(@object, method, %i[first second])
  end

  def test_proc_arity_detection
    # Test various arity scenarios

    # Arity 0
    proc_0 = -> { true }

    assert evaluate_method_with_event_args(@object, proc_0, [:ignored])

    # Arity 1
    proc_1 = ->(obj) { obj.valid? }

    assert evaluate_method_with_event_args(@object, proc_1, [:ignored])

    # Arity 2
    proc_2 = ->(obj, arg) { obj.valid? && arg == :test }

    assert evaluate_method_with_event_args(@object, proc_2, [:test])

    # Arity -1 (splat)
    proc_splat = ->(obj, *args) { obj.valid? && args.include?(:test) }

    assert evaluate_method_with_event_args(@object, proc_splat, %i[test other])
  end

  def test_backward_compatibility_with_no_event_args
    # Should work when no event args are provided
    proc = ->(obj, *args) { obj.valid? && args.empty? }

    assert evaluate_method_with_event_args(@object, proc)
    assert evaluate_method_with_event_args(@object, proc, [])
  end

  def test_fallback_to_standard_evaluate_method
    # Unknown method types should fallback to standard evaluation and raise appropriate error
    custom_object = Object.new

    # Should fallback to standard evaluate_method and raise the same error
    assert_raises(ArgumentError) do
      evaluate_method_with_event_args(@object, custom_object, [:any])
    end
  end
end
