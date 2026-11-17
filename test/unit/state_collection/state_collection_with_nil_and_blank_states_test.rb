# frozen_string_literal: true

require 'test_helper'

# A nil state and a state named :"" are different states, whichever order they
# are defined in.
class StateCollectionWithNilAndBlankStatesTest < StateMachinesTest
  def define(&)
    klass = Class.new { attr_accessor :state }
    machine = StateMachines::Machine.new(klass, initial: nil, &)
    [klass, machine]
  end

  def test_should_define_both_when_blank_comes_first
    _, machine = define { state :'', nil }

    assert_equal [:'', nil], machine.states.map(&:name)
    assert_nil machine.states[nil].value
    assert_equal '', machine.states[:''].value
  end

  def test_should_define_both_when_nil_comes_first
    _, machine = define { state nil, :'' }

    assert_equal [nil, :''], machine.states.map(&:name)
  end

  def test_should_mark_only_the_nil_state_initial
    _, machine = define { state :'', nil }

    assert_predicate machine.states[nil], :initial?
    refute_predicate machine.states[:''], :initial?
  end

  def test_should_list_each_state_once_by_priority
    _, machine = define do
      state :'', nil
      event(:fill) { transition nil => :'' }
    end

    by_priority = machine.states.by_priority

    assert_equal [nil, :''], by_priority.map(&:name)
    assert_equal by_priority.uniq(&:object_id), by_priority
  end

  def test_should_match_each_value_to_its_own_state
    klass, machine = define do
      state :'', nil
      event(:fill) { transition nil => :'' }
    end
    object = klass.new

    assert_same machine.states[nil], machine.states.match(object)

    object.fill

    assert_equal '', object.state
    assert_same machine.states[:''], machine.states.match(object)
  end

  def test_should_not_match_a_blank_value_to_the_nil_state
    klass, machine = define
    object = klass.new
    object.state = ''

    assert_nil machine.states['', :value]
    assert_nil machine.states.match(object)
  end
end
