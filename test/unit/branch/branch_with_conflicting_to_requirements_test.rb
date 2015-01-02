require_relative '../../test_helper'

class BranchWithConflictingToRequirementsTest < StateMachinesTest
  def test_should_raise_an_exception
    exception = assert_raises(ArgumentError) { StateMachines::Branch.new(to: :idling, except_to: :idling) }
    assert_equal 'Conflicting keys: to, except_to', exception.message
  end
end
