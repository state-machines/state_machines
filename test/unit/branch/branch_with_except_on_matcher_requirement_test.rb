require_relative '../../test_helper'

class BranchWithExceptOnMatcherRequirementTest < StateMachinesTest
  def test_should_raise_an_exception
    exception = assert_raises(ArgumentError) { StateMachines::Branch.new(except_on: StateMachines::AllMatcher.instance) }
    assert_equal ':except_on option cannot use matchers; use :on instead', exception.message
  end
end
