# frozen_string_literal: true

require 'test_helper'

class EvalHelpersValidateEvalStringTest < StateMachinesTest
  def validate_eval_string(code)
    StateMachines::EvalHelpers.validate_eval_string(code)
  end

  def test_validate_eval_string_with_safe_code
    validate_eval_string('1 + 1')
    validate_eval_string('object.method')
    validate_eval_string('if condition; end')
    validate_eval_string('lambda { |x| x * 2 }')
    validate_eval_string('value.present?')
  end

  def test_validate_eval_string_with_backtick_execution
    assert_raises(SecurityError) { validate_eval_string('`ls -la`') }
    assert_raises(SecurityError) { validate_eval_string('`rm -rf /`') }
  end

  def test_validate_eval_string_with_system_calls
    assert_raises(SecurityError) { validate_eval_string('system("rm -rf /")') }
    assert_raises(SecurityError) { validate_eval_string('system("malicious")') }
  end

  def test_validate_eval_string_with_exec_calls
    assert_raises(SecurityError) { validate_eval_string('exec("malicious")') }
    assert_raises(SecurityError) { validate_eval_string('exec ("dangerous")') }
  end

  def test_validate_eval_string_with_nested_eval
    assert_raises(SecurityError) { validate_eval_string('eval("dangerous")') }
    assert_raises(SecurityError) { validate_eval_string('eval ("code")') }
  end

  def test_validate_eval_string_with_require_statements
    assert_raises(SecurityError) { validate_eval_string('require "malicious"') }
    assert_raises(SecurityError) { validate_eval_string("require 'dangerous'") }
  end

  def test_validate_eval_string_with_load_statements
    assert_raises(SecurityError) { validate_eval_string('load "malicious"') }
    assert_raises(SecurityError) { validate_eval_string("load 'dangerous'") }
  end

  def test_validate_eval_string_with_file_operations
    assert_raises(SecurityError) { validate_eval_string('File.delete("important")') }
    assert_raises(SecurityError) { validate_eval_string('File.read("/etc/passwd")') }
  end

  def test_validate_eval_string_with_io_operations
    assert_raises(SecurityError) { validate_eval_string('IO.read("/etc/passwd")') }
    assert_raises(SecurityError) { validate_eval_string('IO.popen("ls")') }
  end

  def test_validate_eval_string_with_dir_operations
    assert_raises(SecurityError) { validate_eval_string('Dir.glob("*")') }
    assert_raises(SecurityError) { validate_eval_string('Dir.chdir("/tmp")') }
  end

  def test_validate_eval_string_with_kernel_operations
    assert_raises(SecurityError) { validate_eval_string('Kernel.system("ls")') }
    assert_raises(SecurityError) { validate_eval_string('Kernel.exec("rm")') }
  end

  def test_validate_eval_string_with_invalid_syntax
    assert_raises(ArgumentError) { validate_eval_string('if without end') }
    assert_raises(ArgumentError) { validate_eval_string('def method; end end') }
    assert_raises(ArgumentError) { validate_eval_string('class Foo; def; end') }
  end

  def test_validate_eval_string_with_empty_string
    validate_eval_string('')
  end

  def test_validate_eval_string_with_whitespace_only
    validate_eval_string('   ')
    validate_eval_string("\t\n")
  end

  def test_validate_eval_string_allows_yield
    assert_nil validate_eval_string('yield')
  end

  def test_validate_eval_string_returns_nil
    assert_nil validate_eval_string('1 + 1')
  end
end

class EvalHelpersValidateEvalStringVisibilityTest < StateMachinesTest
  def test_should_be_private_in_including_classes
    refute_includes StateMachines::Branch.public_instance_methods, :validate_eval_string
    assert_includes StateMachines::Branch.private_instance_methods, :validate_eval_string
  end
end

# Every evaluator must apply the same check: Machine used to resolve to a
# separate copy that rejected yield
class EvalHelpersValidateEvalStringEvaluationTest < StateMachinesTest
  def evaluators
    [StateMachines::Machine.new(Class.new), StateMachines::Branch.new, StateMachines::Callback.new(:before, :foo)]
  end

  def test_should_allow_yield_everywhere
    evaluators.each { |evaluator| assert_equal :ran, evaluator.evaluate_method(Object.new, 'yield') { :ran }, evaluator.class.name }
  end

  def test_should_raise_the_same_security_error
    evaluators.each do |evaluator|
      error = assert_raises(SecurityError) { evaluator.evaluate_method(Object.new, '`ls`') }
      assert_equal 'Potentially dangerous code detected in eval string: "`ls`"', error.message
    end
  end

  def test_should_raise_the_same_syntax_error
    expected = assert_raises(ArgumentError) { StateMachines::EvalHelpers.validate_eval_string('if true') }.message

    evaluators.each do |evaluator|
      assert_equal expected, assert_raises(ArgumentError) { evaluator.evaluate_method(Object.new, 'if true') }.message
    end
  end
end
