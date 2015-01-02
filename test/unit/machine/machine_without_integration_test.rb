require_relative '../../test_helper'

class MachineWithoutIntegrationTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @object = @klass.new
  end

  def test_transaction_should_yield
    @yielded = false
    @machine.within_transaction(@object) do
      @yielded = true
    end

    assert @yielded
  end

  def test_invalidation_should_do_nothing
    assert_nil @machine.invalidate(@object, :state, :invalid_transition, [[:event, 'park']])
  end

  def test_reset_should_do_nothing
    assert_nil @machine.reset(@object)
  end

  def test_errors_for_should_be_empty
    assert_equal '', @machine.errors_for(@object)
  end
end

