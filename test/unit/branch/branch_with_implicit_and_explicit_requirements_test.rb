require_relative '../../test_helper'

class BranchWithImplicitAndExplicitRequirementsTest < StateMachinesTest
  def setup
    @branch = StateMachines::Branch.new(parked: :idling, from: :parked)
  end

  def test_should_create_multiple_requirements
    assert_equal 2, @branch.state_requirements.length
  end

  def test_should_create_implicit_requirements_for_implicit_options
    assert(@branch.state_requirements.any? do |state_requirement|
             state_requirement[:from].values == [:parked] && state_requirement[:to].values == [:idling]
           end)
  end

  def test_should_create_implicit_requirements_for_explicit_options
    assert(@branch.state_requirements.any? do |state_requirement|
             state_requirement[:from].values == [:from] && state_requirement[:to].values == [:parked]
           end)
  end
end
