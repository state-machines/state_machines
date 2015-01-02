require_relative '../../test_helper'
require 'stringio'

class MachineWithSuperclassConflictingHelpersAfterDefinitionTest < StateMachinesTest
  def setup
    @original_stderr, $stderr = $stderr, StringIO.new

    @superclass = Class.new
    @klass = Class.new(@superclass)

    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite

    @superclass.class_eval do
      def state?
        true
      end
    end

    @object = @klass.new
  end

  def test_should_call_superclass_attribute_predicate_without_arguments
    assert @object.state?
  end

  def test_should_define_attribute_predicate_with_arguments
    refute @object.state?(:parked)
  end

  def teardown
    $stderr = @original_stderr
  end
end

