require_relative '../../test_helper'

class BranchTest < StateMachinesTest
  def setup
    @branch = StateMachines::Branch.new(from: :parked, to: :idling)
  end

  def test_should_not_raise_exception_if_implicit_option_specified
    StateMachines::Branch.new(invalid: :valid)
  end

  def test_should_not_have_an_if_condition
    assert_nil @branch.if_condition
  end

  def test_should_not_have_an_unless_condition
    assert_nil @branch.unless_condition
  end

  def test_should_have_a_state_requirement
    assert_equal 1, @branch.state_requirements.length
  end

  def test_should_raise_an_exception_if_invalid_match_option_specified
    exception = assert_raises(ArgumentError) { @branch.match(Object.new, invalid: true) }
    assert_equal 'Unknown key: :invalid. Valid keys are: :from, :to, :on, :guard', exception.message
  end
end
