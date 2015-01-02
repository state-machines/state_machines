require_relative '../../test_helper'

class BranchWithExceptToMatcherRequirementTest < StateMachinesTest
  def test_should_raise_an_exception
    exception = assert_raises(ArgumentError) { StateMachines::Branch.new(except_to: StateMachines::AllMatcher.instance) }
    assert_equal ':except_to option cannot use matchers; use :to instead', exception.message
  end
end
