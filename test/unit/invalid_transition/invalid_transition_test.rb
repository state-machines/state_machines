require 'test_helper'

class InvalidTransitionTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @state = @machine.state :parked
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'

    @invalid_transition = StateMachines::InvalidTransition.new(@object, @machine, :ignite)
  end

  def test_should_have_an_object
    assert_equal @object, @invalid_transition.object
  end

  def test_should_have_a_machine
    assert_equal @machine, @invalid_transition.machine
  end

  def test_should_have_an_event
    assert_equal :ignite, @invalid_transition.event
  end

  def test_should_have_a_qualified_event
    assert_equal :ignite, @invalid_transition.qualified_event
  end

  def test_should_have_a_from_value
    assert_equal 'parked', @invalid_transition.from
  end

  def test_should_have_a_from_name
    assert_equal :parked, @invalid_transition.from_name
  end

  def test_should_have_a_qualified_from_name
    assert_equal :parked, @invalid_transition.qualified_from_name
  end

  def test_should_generate_a_message
    assert_equal 'Cannot transition state via :ignite from :parked', @invalid_transition.message
  end
end
