# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

class MachineAsyncOptionTest < StateMachinesTest
  def test_should_require_the_async_gem
    error = assert_raises(LoadError) { StateMachines::Machine.new(Class.new, async: true) }
    assert_match 'state_machines-async', error.message
  end

  def test_should_not_be_async_by_default
    refute_predicate StateMachines::Machine.new(Class.new), :async_mode_enabled?
  end
end
