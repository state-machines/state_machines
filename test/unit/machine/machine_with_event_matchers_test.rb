# frozen_string_literal: true

require 'test_helper'

class MachineWithEventMatchersTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
  end

  def test_should_empty_array_for_all_matcher
    assert_equal [], @machine.event(StateMachines::AllMatcher.instance)
  end

  def test_should_return_referenced_events_for_blacklist_matcher
    assert_instance_of StateMachines::Event, @machine.event(StateMachines::BlacklistMatcher.new([:park]))
  end

  def test_should_not_allow_configurations
    expected_hash = { human_name: 'Parked' }
    expected_message = "Cannot configure states when using matchers (using #{expected_hash.inspect})"
    exception = assert_raises(ArgumentError) do
      @machine.state(StateMachines::BlacklistMatcher.new([:parked]), human_name: 'Parked')
    end
    assert_equal expected_message, exception.message
  end


  def test_should_track_referenced_events
    @machine.event(StateMachines::BlacklistMatcher.new([:park]))
    assert_equal [:park], @machine.events.map { |event| event.name }
  end

  def test_should_eval_context_for_matching_events
    contexts_run = []
    @machine.event(StateMachines::BlacklistMatcher.new([:park])) { contexts_run << name }

    @machine.event :park
    assert_equal [], contexts_run

    @machine.event :ignite
    assert_equal [:ignite], contexts_run

    @machine.event :shift_up, :shift_down
    assert_equal [:ignite, :shift_up, :shift_down], contexts_run
  end
end

