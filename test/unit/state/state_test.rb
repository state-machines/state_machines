require_relative '../../test_helper'

class StateTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @machine.states << @state = StateMachines::State.new(@machine, :parked)
  end

  def test_should_raise_exception_if_invalid_option_specified
    exception = assert_raises(ArgumentError) { StateMachines::State.new(@machine, :parked, invalid: true) }
    assert_equal 'Unknown key: :invalid. Valid keys are: :initial, :value, :cache, :if, :human_name', exception.message
  end

  def test_should_allow_changing_machine
    new_machine = StateMachines::Machine.new(Class.new)
    @state.machine = new_machine
    assert_equal new_machine, @state.machine
  end

  def test_should_allow_changing_value
    @state.value = 1
    assert_equal 1, @state.value
  end

  def test_should_allow_changing_initial
    @state.initial = true
    assert @state.initial
  end

  def test_should_allow_changing_matcher
    matcher = lambda {}
    @state.matcher = matcher
    assert_equal matcher, @state.matcher
  end

  def test_should_allow_changing_human_name
    @state.human_name = 'stopped'
    assert_equal 'stopped', @state.human_name
  end

  def test_should_use_pretty_inspect
    assert_equal '#<StateMachines::State name=:parked value="parked" initial=false>', @state.inspect
  end
end
