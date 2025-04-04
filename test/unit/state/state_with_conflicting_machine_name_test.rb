# frozen_string_literal: true

require 'test_helper'
require 'stringio'

class StateWithConflictingMachineNameTest < StateMachinesTest
  def setup
    @original_stderr = $stderr
    $stderr = StringIO.new

    @klass = Class.new
    @state_machine = StateMachines::Machine.new(@klass, :state)
  end

  def teardown
    $stderr = @original_stderr
  end

  def test_should_output_warning_if_name_conflicts
    StateMachines::State.new(@state_machine, :state)

    assert_match(
      /Instance method "state\?" is already defined in #<Class:.*>, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true./, $stderr.string
    )
  end
end
