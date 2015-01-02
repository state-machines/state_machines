require_relative '../../test_helper'

class BranchWithConflictingOnRequirementsTest < StateMachinesTest
  def test_should_raise_an_exception
    exception = assert_raises(ArgumentError) { StateMachines::Branch.new(on: :ignite, except_on: :ignite) }
    assert_equal 'Conflicting keys: on, except_on', exception.message
  end
end
