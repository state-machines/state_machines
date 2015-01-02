require_relative '../../test_helper'
require 'stringio'

class EventWithConflictingHelpersBeforeDefinitionTest < StateMachinesTest
  def setup
    @original_stderr, $stderr = $stderr, StringIO.new

    @superclass = Class.new do
      def can_ignite?
        0
      end

      def ignite_transition
        0
      end

      def ignite
        0
      end

      def ignite!
        0
      end
    end
    @klass = Class.new(@superclass)
    @machine = StateMachines::Machine.new(@klass)
    @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
    @object = @klass.new
  end

  def test_should_not_redefine_predicate
    assert_equal 0, @object.can_ignite?
  end

  def test_should_not_redefine_transition_accessor
    assert_equal 0, @object.ignite_transition
  end

  def test_should_not_redefine_action
    assert_equal 0, @object.ignite
  end

  def test_should_not_redefine_bang_action
    assert_equal 0, @object.ignite!
  end

  def test_should_output_warning
    expected = %w(can_ignite? ignite_transition ignite ignite!).map do |method|
      "Instance method \"#{method}\" is already defined in #{@superclass}, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n"
    end.join

    assert_equal expected, $stderr.string
  end

  def teardown
    $stderr = @original_stderr
  end
end
