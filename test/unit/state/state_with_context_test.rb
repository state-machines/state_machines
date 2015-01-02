require_relative '../../test_helper'

class StateWithContextTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @ancestors = @klass.ancestors
    @machine.states << @state = StateMachines::State.new(@machine, :idling)

    context = nil
    speed_method = nil
    rpm_method = nil
    @result = @state.context do
      context = self

      def speed
        0
      end

      speed_method = instance_method(:speed)

      def rpm
        1000
      end

      rpm_method = instance_method(:rpm)
    end

    @context = context
    @speed_method = speed_method
    @rpm_method = rpm_method
  end

  def test_should_return_true
    assert_equal true, @result
  end

  def test_should_include_new_module_in_owner_class
    refute_equal @ancestors, @klass.ancestors
    assert_equal [@context], @klass.ancestors - @ancestors
  end

  def test_should_define_each_context_method_in_owner_class
    %w(speed rpm).each { |method| assert @klass.method_defined?(method) }
  end

  def test_should_define_aliased_context_method_in_owner_class
    %w(speed rpm).each { |method| assert @klass.method_defined?("__state_idling_#{method}_#{@context.object_id}__") }
  end

  def test_should_not_use_context_methods_as_owner_class_methods
    refute_equal @speed_method, @state.context_methods[:speed]
    refute_equal @rpm_method, @state.context_methods[:rpm]
  end

  def test_should_use_context_methods_as_aliased_owner_class_methods
    assert_equal @speed_method, @state.context_methods[:"__state_idling_speed_#{@context.object_id}__"]
    assert_equal @rpm_method, @state.context_methods[:"__state_idling_rpm_#{@context.object_id}__"]
  end
end
