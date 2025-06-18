# frozen_string_literal: true

require 'test_helper'

class StateCollectionByDefaultTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @states = StateMachines::StateCollection.new(@machine)
  end

  def test_should_not_have_any_nodes
    assert_equal 0, @states.length
  end

  def test_should_have_a_machine
    assert_equal @machine, @states.machine
  end

  def test_should_be_empty_by_priority
    assert_empty @states.by_priority
  end
end
