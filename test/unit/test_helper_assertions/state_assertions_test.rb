# frozen_string_literal: true

require 'test_helper'

class StateAssertionsTest < StateMachinesTest
  class Tank
    attr_accessor :state

    state_machine :state, initial: nil do
      state :'', nil

      event :fill do
        transition nil => :''
      end
    end
  end

  class Rover
    attr_accessor :state

    state_machine :state, initial: 'parked' do
      event :ignite do
        transition 'parked' => 'idling'
      end
    end
  end

  def setup
    @tank = Tank.new
  end

  def assert_assertion_fails(pattern, &)
    error = assert_raises(Minitest::Assertion, &)
    assert_match pattern, error.message
  end

  def test_state_passes_for_the_nil_state
    assert_sm_state(@tank, nil)
  end

  def test_state_fails_for_blank_when_nil
    assert_assertion_fails(/to be :"", but was nil/) { assert_sm_state(@tank, :'') }
  end

  def test_state_fails_for_nil_when_blank
    @tank.fill

    assert_sm_state(@tank, :'')
    assert_assertion_fails(/to be nil, but was :""/) { assert_sm_state(@tank, nil) }
  end

  def test_state_treats_string_and_symbol_names_alike
    rover = Rover.new

    assert_sm_state(rover, :parked)
    assert_sm_state(rover, 'parked')
  end

  def test_sync_execution_distinguishes_nil_from_blank
    assert_sm_sync_execution(@tank, :fill, :'')
  end

  def test_sync_execution_fails_for_nil_when_blank
    assert_assertion_fails(/but got ''/) { assert_sm_sync_execution(Tank.new, :fill, nil) }
  end
end
