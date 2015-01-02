require_relative '../../test_helper'

class CallbackWithAroundTypeAndMultipleMethodsTest < StateMachinesTest
  def setup
    @callback = StateMachines::Callback.new(:around, :run_1, :run_2)

    class << @object = Object.new
      attr_accessor :before_callbacks
      attr_accessor :after_callbacks

      def run_1
        (@before_callbacks ||= []) << :run_1
        yield
        (@after_callbacks ||= []) << :run_1
      end

      def run_2
        (@before_callbacks ||= []) << :run_2
        yield
        (@after_callbacks ||= []) << :run_2
      end
    end
  end

  def test_should_succeed
    assert @callback.call(@object)
  end

  def test_should_evaluate_before_callbacks_in_order
    @callback.call(@object)
    assert_equal [:run_1, :run_2], @object.before_callbacks
  end

  def test_should_evaluate_after_callbacks_in_reverse_order
    @callback.call(@object)
    assert_equal [:run_2, :run_1], @object.after_callbacks
  end

  def test_should_call_block_after_before_callbacks
    @callback.call(@object) { (@object.before_callbacks ||= []) << :block }
    assert_equal [:run_1, :run_2, :block], @object.before_callbacks
  end

  def test_should_call_block_before_after_callbacks
    @callback.call(@object) { (@object.after_callbacks ||= []) << :block }
    assert_equal [:block, :run_2, :run_1], @object.after_callbacks
  end

  def test_should_halt_if_first_doesnt_yield
    class << @object
      remove_method :run_1
      def run_1
        (@before_callbacks ||= []) << :run_1
      end
    end

    catch(:halt) do
      @callback.call(@object) { (@object.before_callbacks ||= []) << :block }
    end

    assert_equal [:run_1], @object.before_callbacks
    assert_nil @object.after_callbacks
  end

  def test_should_halt_if_last_doesnt_yield
    class << @object
      remove_method :run_2
      def run_2
        (@before_callbacks ||= []) << :run_2
      end
    end

    catch(:halt) { @callback.call(@object) }
    assert_equal [:run_1, :run_2], @object.before_callbacks
    assert_nil @object.after_callbacks
  end

  def test_should_not_evaluate_further_methods_if_after_halts
    class << @object
      remove_method :run_2
      def run_2
        (@before_callbacks ||= []) << :run_2
        yield
        (@after_callbacks ||= []) << :run_2
        throw :halt
      end
    end

    catch(:halt) { @callback.call(@object) }
    assert_equal [:run_1, :run_2], @object.before_callbacks
    assert_equal [:run_2], @object.after_callbacks
  end
end
