require_relative '../../test_helper'

class MachineWithActionAlreadyOverriddenTest < StateMachinesTest
  def setup
    @superclass = Class.new do
      def save
      end
    end
    @klass = Class.new(@superclass)

    StateMachines::Machine.new(@klass, action: :save)
    @machine = StateMachines::Machine.new(@klass, :status, action: :save)
    @object = @klass.new
  end

  def test_should_not_redefine_action
    assert_equal 1, @klass.ancestors.select { |ancestor| ![@klass, @superclass].include?(ancestor) && ancestor.method_defined?(:save) }.length
  end

  def test_should_mark_action_hook_as_defined
    assert @machine.action_hook?
  end
end
