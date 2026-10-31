# frozen_string_literal: true

module StateMachines
  module AsyncMode
    # Error class for async-specific transition failures
    class AsyncTransitionError < StateMachines::Error
      def initialize(object, machines, failed_events)
        @object = object
        @machines = machines
        @failed_events = failed_events
        super("Failed to perform async transitions: #{failed_events.join(', ')}")
      end

      attr_reader :object, :machines, :failed_events
    end

    # Async-aware transition collection that can execute transitions concurrently
    class AsyncTransitionCollection < TransitionCollection
      # Performs the collection inside an Async task, entering a reactor when
      # the caller is not already in one.
      #
      # The callbacks and the action belong to the collection, not to one
      # transition, so they run once. What is asynchronous is the collection as
      # a whole, which is what lets an I/O-bound action yield to its reactor.
      def perform_async(&)
        return perform(&) if defined?(::Async::Task) && ::Async::Task.current?

        Async { perform(&) }.wait
      end

      # Performs the collection on another thread and waits for its result.
      def perform_threaded(&)
        Thread.new { perform(&) }.value
      end

      private

      # Override run_actions to be thread-safe when needed
      def run_actions(&)
        catch_exceptions do
          @success = if block_given?
                      result = yield
                      actions.each { |action| results[action] = result }
                      !!result
                    else
                      actions.compact.each do |action|
                        next if skip_actions

                        # Use thread-safe write for results
                        if object.respond_to?(:state_machine_mutex)
                          object.state_machine_mutex.with_write_lock do
                            results[action] = object.send(action)
                          end
                        else
                          results[action] = object.send(action)
                        end
                      end
                      results.values.all?
                    end
        end
      end
    end
  end
end
