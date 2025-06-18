# frozen_string_literal: true

require 'test_helper'

class CallbackWithMethodArgumentTest < StateMachinesTest
  def setup
    @callback = StateMachines::Callback.new(:before, ->(*args) { @args = args })

    @object = Object.new
    @result = @callback.call(@object)
  end

  def test_should_be_successful
    assert @result
  end

  def test_should_call_with_empty_context
    assert_equal [@object], @args
  end
end
