# frozen_string_literal: true

require 'test_helper'

class StateWithConflictingHelpersAfterDefinitionTest < StateMachinesTest
  class SuperKlass
    def parked?
      false
    end
  end

  def setup
    @original_stderr = $stderr
    $stderr = StringIO.new

    @klass = Class.new(SuperKlass)

    @machine = StateMachines::Machine.new(@klass)

    @output = capture_io { @machine.state :parked }.join
    @object = @klass.new
  end

  def teardown
    $stderr = @original_stderr
  end

  def test_should_not_override_state_predicate
    assert_equal false, @object.parked?
  end

  def test_should_still_allow_super_chaining
    @klass.class_eval do
      def parked?
        super
      end
    end

    assert_equal false, @object.parked?
  end

  def test_should_output_warning
    assert_match(/Instance method "parked\?" is already defined/, @output)
  end
end
