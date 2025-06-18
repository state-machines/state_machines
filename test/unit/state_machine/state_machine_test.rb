# frozen_string_literal: true

require 'test_helper'

class StateMachineTest < StateMachinesTest
  def setup
    @klass = Class.new
  end

  def test_should_allow_state_machines_on_any_class
    assert_respond_to @klass, :state_machine
  end

  def test_should_evaluate_block_within_machine_context
    responded = false
    @klass.state_machine(:state) do
      responded = respond_to?(:event)
    end

    assert responded
  end
end
