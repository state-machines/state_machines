# frozen_string_literal: true

require 'test_helper'

# Binding a block to the object must not replace it: introspection and
# renderers read the configured methods and label them by source_location.
class CallbackWithBoundMethodIdentityTest < StateMachinesTest
  def setup
    @block = ->(*args) { [self, *args] }
    @line = __LINE__ - 1
    @callback = StateMachines::Callback.new(:before, do: @block, bind_to_object: true)
    @methods = @callback.instance_variable_get(:@methods)
  end

  def test_should_keep_the_users_block
    assert_same @block, @methods.first
  end

  def test_should_keep_its_source_location
    assert_equal [__FILE__, @line], @methods.first.source_location
  end

  def test_should_keep_its_inspect
    assert_equal @block.inspect, @methods.first.inspect
  end

  def test_should_still_run_it_bound_to_the_object
    object = Object.new
    result = nil
    callback = StateMachines::Callback.new(:before, do: ->(*args) { result = [self, *args] }, bind_to_object: true)
    callback.call(object, {}, 1)

    assert_equal [object, 1], result
  end

  def test_should_keep_a_symbol_proc_recognisable
    callback = StateMachines::Callback.new(:before, do: :upcase.to_proc, bind_to_object: true)

    assert_match(/\(&:upcase\)/, callback.instance_variable_get(:@methods).first.inspect)
  end

  def test_should_keep_a_block_given_to_the_callback
    block = proc { :ran }
    callback = StateMachines::Callback.new(:before, bind_to_object: true, &block)

    assert_same block, callback.instance_variable_get(:@methods).first
  end
end

class CallbackAssertionWithBoundBlockTest < StateMachinesTest
  AUDIT = ->(*) {}

  def test_should_match_a_bound_block_by_identity
    machine = StateMachines::Machine.new(Class.new, initial: :parked) do
      event(:ignite) { transition parked: :idling }
      before_transition on: :ignite, do: AUDIT, bind_to_object: true
    end

    assert_before_transition(machine, on: :ignite, do: AUDIT)
  end
end
