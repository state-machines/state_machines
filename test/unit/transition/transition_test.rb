require_relative '../../test_helper'

class TransitionTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'

    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end

  def test_should_have_an_object
    assert_equal @object, @transition.object
  end

  def test_should_have_a_machine
    assert_equal @machine, @transition.machine
  end

  def test_should_have_an_event
    assert_equal :ignite, @transition.event
  end

  def test_should_have_a_qualified_event
    assert_equal :ignite, @transition.qualified_event
  end

  def test_should_have_a_human_event
    assert_equal 'ignite', @transition.human_event
  end

  def test_should_have_a_from_value
    assert_equal 'parked', @transition.from
  end

  def test_should_have_a_from_name
    assert_equal :parked, @transition.from_name
  end

  def test_should_have_a_qualified_from_name
    assert_equal :parked, @transition.qualified_from_name
  end

  def test_should_have_a_human_from_name
    assert_equal 'parked', @transition.human_from_name
  end

  def test_should_have_a_to_value
    assert_equal 'idling', @transition.to
  end

  def test_should_have_a_to_name
    assert_equal :idling, @transition.to_name
  end

  def test_should_have_a_qualified_to_name
    assert_equal :idling, @transition.qualified_to_name
  end

  def test_should_have_a_human_to_name
    assert_equal 'idling', @transition.human_to_name
  end

  def test_should_have_an_attribute
    assert_equal :state, @transition.attribute
  end

  def test_should_not_have_an_action
    assert_nil @transition.action
  end

  def test_should_not_be_transient
    assert_equal false, @transition.transient?
  end

  def test_should_generate_attributes
    expected = { object: @object, attribute: :state, event: :ignite, from: 'parked', to: 'idling' }
    assert_equal expected, @transition.attributes
  end

  def test_should_have_empty_args
    assert_equal [], @transition.args
  end

  def test_should_not_have_a_result
    assert_nil @transition.result
  end

  def test_should_use_pretty_inspect
    assert_equal '#<StateMachines::Transition attribute=:state event=:ignite from="parked" from_name=:parked to="idling" to_name=:idling>', @transition.inspect
  end
end
