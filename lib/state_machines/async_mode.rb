# frozen_string_literal: true

# Ruby Engine Compatibility Check
# The async gem requires native extensions and Fiber scheduler support
# which are not available on JRuby or TruffleRuby
if RUBY_ENGINE == 'jruby' || RUBY_ENGINE == 'truffleruby'
  raise LoadError, <<~ERROR
    StateMachines::AsyncMode is not available on #{RUBY_ENGINE}.

    The async gem requires native extensions (io-event) and Fiber scheduler support
    which are not implemented in #{RUBY_ENGINE}. AsyncMode is only supported on:

    • MRI Ruby (CRuby) 3.2+
    • Other Ruby engines with full Fiber scheduler support

    If you need async support on #{RUBY_ENGINE}, consider using:
    • java.util.concurrent classes (JRuby)
    • Native threading libraries for your platform
    • Or stick with synchronous state machines
  ERROR
end

# Load required gems with version constraints
gem 'async', '>= 2.25.0'
gem 'concurrent-ruby', '>= 1.3.5'  # Security is not negotiable - enterprise-grade thread safety required

require 'async'
require 'concurrent-ruby'

# Load all async mode components
require_relative 'async_mode/thread_safe_state'
require_relative 'async_mode/async_events'
require_relative 'async_mode/async_event_extensions'
require_relative 'async_mode/async_machine'
require_relative 'async_mode/async_transition_collection'

module StateMachines
  # AsyncMode provides asynchronous state machine capabilities using the async gem
  # This module enables concurrent, thread-safe state operations for high-performance applications
  #
  # @example Basic usage
  #   class AutonomousDrone < StarfleetShip
  #     state_machine :teleporter_status, async: true do
  #       event :power_up do
  #         transition offline: :charging
  #       end
  #     end
  #   end
  #
  #   drone = AutonomousDrone.new
  #   Async do
  #     result = drone.fire_event_async(:power_up)  # => true
  #     task = drone.power_up_async!               # => Async::Task
  #   end
  #
  # @since 0.31.0
  module AsyncMode
    # All components are loaded from separate files:
    # - ThreadSafeState: Mutex-based thread safety
    # - AsyncEvents: Async event firing methods
    # - AsyncEventExtensions: Event method generation
    # - AsyncMachine: Machine-level async capabilities
    # - AsyncTransitionCollection: Concurrent transition execution
  end
end
