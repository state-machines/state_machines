# frozen_string_literal: true

require 'test_helper'

# A transition's before chain is taken when it starts: a callback registered
# while the chain runs applies from the next transition, not the current one.
class TransitionBeforeChainSnapshotTest < StateMachinesTest
  def setup
    @log = log = []
    @klass = Class.new
    @machine = machine = StateMachines::Machine.new(@klass, initial: :parked) do
      event(:ignite) { transition parked: :idling }
      event(:park) { transition idling: :parked }
    end
    registered = false
    @machine.before_transition do
      log << :first
      unless registered
        registered = true
        machine.before_transition { log << :late }
      end
    end
  end

  def test_should_not_run_a_callback_registered_during_the_chain
    @klass.new.ignite

    assert_equal [:first], @log
  end

  def test_should_run_it_from_the_next_transition
    object = @klass.new
    object.ignite
    object.park

    assert_equal %i[first first late], @log
  end
end
