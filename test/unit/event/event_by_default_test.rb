require_relative '../../test_helper'


class EventByDefaultTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.events << @event = StateMachines::Event.new(@machine, :ignite)

    @object = @klass.new
  end

  def test_should_have_a_machine
    assert_equal @machine, @event.machine
  end

  def test_should_have_a_name
    assert_equal :ignite, @event.name
  end

  def test_should_have_a_qualified_name
    assert_equal :ignite, @event.qualified_name
  end

  def test_should_have_a_human_name
    assert_equal 'ignite', @event.human_name
  end

  def test_should_not_have_any_branches
    assert @event.branches.empty?
  end

  def test_should_have_no_known_states
    assert @event.known_states.empty?
  end

  def test_should_not_be_able_to_fire
    refute @event.can_fire?(@object)
  end

  def test_should_not_have_a_transition
    assert_nil @event.transition_for(@object)
  end

  def test_should_define_a_predicate
    assert @object.respond_to?(:can_ignite?)
  end

  def test_should_define_a_transition_accessor
    assert @object.respond_to?(:ignite_transition)
  end

  def test_should_define_an_action
    assert @object.respond_to?(:ignite)
  end

  def test_should_define_a_bang_action
    assert @object.respond_to?(:ignite!)
  end
end
