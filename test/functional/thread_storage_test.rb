# frozen_string_literal: true

require 'test_helper'
require 'files/models/thread_storage'

# Tests related to https://github.com/state-machines/state_machines/issues/152
class ThreadStorageTest < Minitest::Test
  def setup
    ThreadStorage.flush!
    @machine = ThreadStorage.new
  end

  # A state transition should not change context to a different Thread. This
  # also includes keeping around things added to the store during the transition
  # https://github.com/state-machines/state_machines/issues/152#issuecomment-3329710026
  def test_should_not_change_object_id_in_thread_current
    @machine.fire_state_event :start

    assert_equal %i[
      before_transition
      before_around_transition
      after_around_transition
      after_transition
    ], ThreadStorage.store
  end
end
