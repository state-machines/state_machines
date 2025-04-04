# frozen_string_literal: true

require_relative '../../test_helper'

class StateWithConflictingHelpersTest < StateMachinesTest
  class SuperKlass
    def parked?
      true
    end
  end

  def setup
    @klass = Class.new(SuperKlass)

    @machine = StateMachines::Machine.new(@klass)
    @object = @klass.new

    @original_stderr = $stderr
    $stderr = StringIO.new
    begin
      @machine.state :parked
      @output = $stderr.string
    ensure
      $stderr = @original_stderr
    end
  ensure
    $stderr = @original_stderr
  end

  def teardown; end

  def test_should_output_warning
    assert_match(/Instance method "parked\?" is already defined/, @output)
  end
end
