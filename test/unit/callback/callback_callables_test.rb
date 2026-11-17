# frozen_string_literal: true

require 'test_helper'

class CallbackCallablesTest < StateMachinesTest
  def setup
    @lambda = ->(_object) {}
    @block = proc {}
    @callback = StateMachines::Callback.new(:before, :log, 'audit', do: [:notify, @lambda], &@block)
  end

  def test_should_list_the_methods_in_configured_order
    assert_equal [:log, 'audit', :notify, @lambda, @block], @callback.callables
  end

  def test_should_return_the_users_own_procs
    assert_same @lambda, @callback.callables[3]
    assert_same @block, @callback.callables[4]
  end

  def test_should_be_frozen
    assert_predicate @callback.callables, :frozen?
    assert_raises(FrozenError) { @callback.callables << :other }
  end

  def test_should_not_shadow_object_methods
    assert_includes @callback.methods, :callables
  end

  def test_should_run_after_being_read
    object = Object.new
    ran = []
    callback = StateMachines::Callback.new(:before, do: ->(target) { ran << target })
    callback.callables
    callback.call(object)

    assert_equal [object], ran
  end
end

class CallbackCallablesWithBoundObjectTest < StateMachinesTest
  def setup
    @lambda = ->(*args) { [self, *args] }
    @callback = StateMachines::Callback.new(:before, :log, do: @lambda, bind_to_object: true)
  end

  def test_should_return_the_users_proc_not_the_binding_proxy
    assert_equal [:log, @lambda], @callback.callables
    assert_same @lambda, @callback.callables.last
  end

  def test_should_keep_its_source_location
    assert_equal @lambda.source_location, @callback.callables.last.source_location
  end

  def test_should_still_run_it_bound_to_the_object
    object = Object.new
    result = nil
    callback = StateMachines::Callback.new(:before, do: ->(*args) { result = [self, *args] }, bind_to_object: true)
    callback.call(object, {}, 1)

    assert_equal [object, 1], result
  end

  def test_should_be_frozen
    assert_predicate @callback.callables, :frozen?
  end
end
