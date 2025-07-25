# frozen_string_literal: true

require 'test_helper'

class MachineCollectionByDefaultTest < StateMachinesTest
  def setup
    @machines = StateMachines::MachineCollection.new
  end

  def test_should_not_have_any_machines
    assert_empty @machines
  end
end
