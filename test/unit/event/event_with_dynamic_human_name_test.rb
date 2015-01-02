require_relative '../../test_helper'

class EventWithDynamicHumanNameTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.events << @event = StateMachines::Event.new(@machine, :ignite, human_name: lambda { |_event, object| ['start', object] })
  end

  def test_should_use_custom_human_name
    human_name, klass = @event.human_name
    assert_equal 'start', human_name
    assert_equal @klass, klass
  end

  def test_should_allow_custom_class_to_be_passed_through
    human_name, klass = @event.human_name(1)
    assert_equal 'start', human_name
    assert_equal 1, klass
  end

  def test_should_not_cache_value
    refute_same @event.human_name, @event.human_name
  end
end

