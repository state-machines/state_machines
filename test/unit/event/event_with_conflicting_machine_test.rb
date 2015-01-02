require_relative '../../test_helper'
require 'stringio'

class EventWithConflictingMachineTest < StateMachinesTest
  def setup
    @original_stderr, $stderr = $stderr, StringIO.new

    @klass = Class.new
    @state_machine = StateMachines::Machine.new(@klass, :state)
    @state_machine.state :parked, :idling
    @state_machine.events << @state_event = StateMachines::Event.new(@state_machine, :ignite)
  end

  def test_should_not_overwrite_first_event
    @status_machine = StateMachines::Machine.new(@klass, :status)
    @status_machine.state :first_gear, :second_gear
    @status_machine.events << @status_event = StateMachines::Event.new(@status_machine, :ignite)

    @object = @klass.new
    @object.state = 'parked'
    @object.status = 'first_gear'

    @state_event.transition(parked: :idling)
    @status_event.transition(parked: :first_gear)

    @object.ignite
    assert_equal 'idling', @object.state
    assert_equal 'first_gear', @object.status
  end

  def test_should_output_warning
    @status_machine = StateMachines::Machine.new(@klass, :status)
    @status_machine.events << @status_event = StateMachines::Event.new(@status_machine, :ignite)

    assert_equal "Event :ignite for :status is already defined in :state\n", $stderr.string
  end

  def test_should_not_output_warning_if_using_different_namespace
    @status_machine = StateMachines::Machine.new(@klass, :status, namespace: 'alarm')
    @status_machine.events << @status_event = StateMachines::Event.new(@status_machine, :ignite)

    assert_equal '', $stderr.string
  end

  def teardown
    $stderr = @original_stderr
  end
end
