# frozen_string_literal: true

require_relative '../../test_helper'

class BranchWithInvalidStateGuardsTest < Minitest::Test
  def setup
    @klass = Class.new do
      def self.name
        'Vehicle'
      end
      state_machine :state1, initial: :parked
      state_machine :state2, initial: :off
    end
    @object = @klass.new
  end

  def test_should_raise_error_for_nonexistent_machine
    branch = StateMachines::Branch.new(if_state: { nonexistent_machine: :on })
    exception = assert_raises(ArgumentError) { branch.matches?(@object) }
    assert_equal "State machine 'nonexistent_machine' is not defined for Vehicle", exception.message
  end

  def test_should_raise_error_for_nonexistent_state
    branch = StateMachines::Branch.new(if_state: { state1: :nonexistent_state })
    exception = assert_raises(ArgumentError) { branch.matches?(@object) }
    assert_equal "State 'nonexistent_state' is not defined in state machine 'state1'", exception.message
  end

  def test_should_raise_error_for_nonexistent_machine_in_unless
    branch = StateMachines::Branch.new(unless_state: { nonexistent_machine: :on })
    exception = assert_raises(ArgumentError) { branch.matches?(@object) }
    assert_equal "State machine 'nonexistent_machine' is not defined for Vehicle", exception.message
  end

  def test_should_raise_error_for_nonexistent_state_in_unless
    branch = StateMachines::Branch.new(unless_state: { state1: :nonexistent_state })
    exception = assert_raises(ArgumentError) { branch.matches?(@object) }
    assert_equal "State 'nonexistent_state' is not defined in state machine 'state1'", exception.message
  end
end
