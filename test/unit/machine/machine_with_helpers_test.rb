require_relative '../../test_helper'

class MachineWithHelpersTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @object = @klass.new
  end

  def test_should_throw_exception_with_invalid_scope
    assert_raises(RUBY_VERSION < '1.9' ? IndexError : KeyError) { @machine.define_helper(:invalid, :park) {} }
  end
end

