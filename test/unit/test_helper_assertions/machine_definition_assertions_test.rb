# frozen_string_literal: true

require 'test_helper'

class MachineDefinitionAssertionsTest < StateMachinesTest
  class Lamp
    attr_accessor :switch_value

    state_machine :switch, attribute: :switch_value, initial: :off do
      event(:flip) { transition off: :on, on: :off }
      event(:smash) { transition all => :broken }
      event(:stay) { transition all => same }
    end
  end

  def setup
    @machine = Lamp.state_machine(:switch)
  end

  def assert_assertion_fails(&)
    assert_raises(Minitest::Assertion, &)
  end

  def test_states_list_resolves_string_names
    assert_sm_states_list(@machine, %w[off on broken])
  end

  def test_states_list_fails_on_a_missing_state
    assert_assertion_fails { assert_sm_states_list(@machine, %i[off on]) }
  end

  def test_states_list_includes_nil_only_when_expected
    machine = StateMachines::Machine.new(Class.new) { state :parked }

    assert_sm_states_list(machine, [:parked])
    assert_sm_states_list(machine, [nil, :parked])
  end

  def test_state_not_defined_resolves_string_names
    assert_assertion_fails { refute_sm_state_defined(@machine, 'on') }
    refute_sm_state_defined(@machine, :dimmed)
  end

  def test_initial_state_resolves_string_names
    assert_sm_initial_state(@machine, 'off')
  end

  def test_initial_state_does_not_define_states
    assert_raises(IndexError) { assert_sm_initial_state(@machine, :dimmed) }
    assert_nil @machine.states[:dimmed]
  end

  def test_final_state
    assert_sm_final_state(@machine, :broken)
    assert_assertion_fails { assert_sm_final_state(@machine, :on) }
  end

  def test_transition_not_allowed_on_a_missing_branch
    refute_sm_transition_allowed(@machine, from: :broken, to: :on, on: :flip)
  end

  def test_transition_not_allowed_fails_on_a_branch
    assert_assertion_fails { refute_sm_transition_allowed(@machine, from: 'off', to: 'on', on: 'flip') }
  end

  def test_transition_not_allowed_fails_on_a_loopback
    assert_assertion_fails { refute_sm_transition_allowed(@machine, from: :on, to: :on, on: :stay) }
  end

  def test_transition_not_allowed_raises_on_unknown_names
    assert_raises(IndexError) { refute_sm_transition_allowed(@machine, from: :off, to: :on, on: :toggle) }
  end

  def test_event_triggers_reads_the_machine_attribute
    assert_sm_event_triggers(Lamp.new, :flip, :switch)
  end

  def test_event_not_triggers_reads_the_machine_attribute
    assert_assertion_fails { refute_sm_event_triggers(Lamp.new, :flip, :switch) }
  end

  def test_triggers_event_resolves_string_event_names
    lamp = Lamp.new

    assert_sm_triggers_event(lamp, 'flip', machine_name: :switch) { lamp.flip }
  end
end
