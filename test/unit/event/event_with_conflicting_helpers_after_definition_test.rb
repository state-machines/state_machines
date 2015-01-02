require_relative '../../test_helper'
require 'stringio'

class EventWithConflictingHelpersAfterDefinitionTest < StateMachinesTest
  def setup
    @original_stderr, $stderr = $stderr, StringIO.new

    @klass = Class.new do
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

  def test_should_allow_super_chaining
    @klass.class_eval do
      def can_ignite?
        super
      end

      def ignite_transition
        super
      end

      def ignite
        super
      end

      def ignite!
        super
      end
    end

    assert_equal false, @object.can_ignite?
    assert_equal nil, @object.ignite_transition
    assert_equal false, @object.ignite
    assert_raises(StateMachines::InvalidTransition) { @object.ignite! }
  end

  def test_should_not_output_warning
    assert_equal '', $stderr.string
  end

  def teardown
    $stderr = @original_stderr
  end
end

