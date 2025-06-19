# frozen_string_literal: true

require 'test_helper'
require_relative '../../../lib/state_machines/machine/validation'
require_relative '../../../lib/state_machines/syntax_validator'

class MachineValidationTest < StateMachinesTest
  include StateMachines::Machine::Validation

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
end
