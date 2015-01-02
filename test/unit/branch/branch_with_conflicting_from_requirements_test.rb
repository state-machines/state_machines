require_relative '../../test_helper'

class BranchWithConflictingFromRequirementsTest < StateMachinesTest
  def test_should_raise_an_exception
    exception = assert_raises(ArgumentError) { StateMachines::Branch.new(from: :parked, except_from: :parked) }
    assert_equal 'Conflicting keys: from, except_from', exception.message
  end
end
