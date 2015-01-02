require_relative '../../test_helper'
require 'stringio'

class StateWithConflictingMachineTest < StateMachinesTest
  def setup
    @original_stderr, $stderr = $stderr, StringIO.new

    @klass = Class.new
    @state_machine = StateMachines::Machine.new(@klass, :state)
    @state_machine.states << @state = StateMachines::State.new(@state_machine, :parked)
  end

  def test_should_output_warning_if_using_different_attribute
    @status_machine = StateMachines::Machine.new(@klass, :status)
    @status_machine.states << @state = StateMachines::State.new(@status_machine, :parked)

    assert_equal "State :parked for :status is already defined in :state\n", $stderr.string
  end

  def test_should_not_output_warning_if_using_same_attribute
    @status_machine = StateMachines::Machine.new(@klass, :status, attribute: :state)
    @status_machine.states << @state = StateMachines::State.new(@status_machine, :parked)

    assert_equal '', $stderr.string
  end

  def test_should_not_output_warning_if_using_different_namespace
    @status_machine = StateMachines::Machine.new(@klass, :status, namespace: 'alarm')
    @status_machine.states << @state = StateMachines::State.new(@status_machine, :parked)

    assert_equal '', $stderr.string
  end

  def teardown
    $stderr = @original_stderr
  end
end
