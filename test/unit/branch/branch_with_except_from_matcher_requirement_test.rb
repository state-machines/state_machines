require_relative '../../test_helper'

class BranchWithExceptFromMatcherRequirementTest < StateMachinesTest
  def test_should_raise_an_exception
    exception = assert_raises(ArgumentError) { StateMachines::Branch.new(except_from: StateMachines::AllMatcher.instance) }
    assert_equal ':except_from option cannot use matchers; use :from instead', exception.message
  end
end
