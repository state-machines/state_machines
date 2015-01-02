require_relative '../../test_helper'

class BranchWithMultipleImplicitRequirementsTest < StateMachinesTest
  def setup
    @object = Object.new
    @branch = StateMachines::Branch.new(parked: :idling, idling: :first_gear, on: :ignite)
  end

  def test_should_create_multiple_state_requirements
    assert_equal 2, @branch.state_requirements.length
  end

  def test_should_not_match_event_as_state_requirement
    refute @branch.matches?(@object, from: :on, to: :ignite)
  end

  def test_should_match_if_from_included_in_any
    assert @branch.matches?(@object, from: :parked)
    assert @branch.matches?(@object, from: :idling)
  end

  def test_should_not_match_if_from_not_included_in_any
    refute @branch.matches?(@object, from: :first_gear)
  end

  def test_should_match_if_to_included_in_any
    assert @branch.matches?(@object, to: :idling)
    assert @branch.matches?(@object, to: :first_gear)
  end

  def test_should_not_match_if_to_not_included_in_any
    refute @branch.matches?(@object, to: :parked)
  end

  def test_should_match_if_all_options_match
    assert @branch.matches?(@object, from: :parked, to: :idling, on: :ignite)
    assert @branch.matches?(@object, from: :idling, to: :first_gear, on: :ignite)
  end

  def test_should_not_match_if_any_options_do_not_match
    refute @branch.matches?(@object, from: :parked, to: :idling, on: :park)
    refute @branch.matches?(@object, from: :parked, to: :first_gear, on: :park)
  end

  def test_should_include_all_known_states
    assert_equal [:first_gear, :idling, :parked], @branch.known_states.sort_by { |state| state.to_s }
  end

  def test_should_not_duplicate_known_statse
    branch = StateMachines::Branch.new(parked: :idling, first_gear: :idling)
    assert_equal [:first_gear, :idling, :parked], branch.known_states.sort_by { |state| state.to_s }
  end
end
