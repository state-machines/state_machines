# frozen_string_literal: true

require 'test_helper'

class CallbackWithIfConditionTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_call_if_true
    callback = StateMachines::Callback.new(:before, if: -> { true }, do: -> {})

    assert callback.call(@object)
  end

  def test_should_not_call_if_false
    callback = StateMachines::Callback.new(:before, if: -> { false }, do: -> {})

    refute callback.call(@object)
  end
end
