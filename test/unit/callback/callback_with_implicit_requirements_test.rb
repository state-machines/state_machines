require_relative '../../test_helper'

class CallbackWithImplicitRequirementsTest < StateMachinesTest
  def setup
    @object = Object.new
    @callback = StateMachines::Callback.new(:before, parked: :idling, on: :ignite, do: lambda {})
  end

  def test_should_call_with_empty_context
    assert @callback.call(@object, {})
  end

  def test_should_not_call_if_from_not_included
    refute @callback.call(@object, from: :idling)
  end

  def test_should_not_call_if_to_not_included
    refute @callback.call(@object, to: :parked)
  end

  def test_should_not_call_if_on_not_included
    refute @callback.call(@object, on: :park)
  end

  def test_should_call_if_all_requirements_met
    assert @callback.call(@object, from: :parked, to: :idling, on: :ignite)
  end

  def test_should_include_in_known_states
    assert_equal [:parked, :idling], @callback.known_states
  end
end
