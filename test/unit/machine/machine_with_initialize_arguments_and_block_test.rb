require_relative '../../test_helper'

class MachineWithInitializeArgumentsAndBlockTest < StateMachinesTest
  def setup
    @superclass = Class.new do
      attr_reader :args
      attr_reader :block_given

      def initialize(*args)
        @args = args
        @block_given = block_given?
      end
    end
    @klass = Class.new(@superclass)
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @object = @klass.new(1, 2, 3) {}
  end

  def test_should_initialize_state
    assert_equal 'parked', @object.state
  end

  def test_should_preserve_arguments
    assert_equal [1, 2, 3], @object.args
  end

  def test_should_preserve_block
    assert @object.block_given
  end
end

