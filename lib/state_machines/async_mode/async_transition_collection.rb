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
      # Performs transitions asynchronously using Async
      # Provides better concurrency for I/O-bound operations
      def perform_async(&block)
        reset

        unless defined?(::Async::Task) && ::Async::Task.current?
          return Async do
            perform_async(&block)
          end.wait
        end

        if valid?
          # Create async tasks for each transition
          tasks = map do |transition|
            Async do
              if use_event_attributes? && !block_given?
                transition.transient = true
                transition.machine.write_safely(object, :event_transition, transition)
                run_actions
                transition
              else
                within_transaction do
                  catch(:halt) { run_callbacks(&block) }
                  rollback unless success?
                end
                transition
              end
            end
          end

          # Wait for all tasks to complete
          completed_transitions = []
          tasks.each do |task|
            begin
              result = task.wait
              completed_transitions << result if result
            rescue StandardError => e
              # Handle individual transition failures
              rollback
              raise AsyncTransitionError.new(object, map(&:machine), [e.message])
            end
          end

          # Check if all transitions succeeded
          @success = completed_transitions.length == length
        end

        success?
      end

      # Performs transitions concurrently using threads
      # Better for CPU-bound operations but requires more careful synchronization
      def perform_threaded(&block)
        reset

        if valid?
          # Use basic thread approach
          threads = []
          results = []
          results_mutex = Concurrent::ReentrantReadWriteLock.new

          each do |transition|
            threads << Thread.new do
              begin
                result = if use_event_attributes? && !block_given?
                          transition.transient = true
                          transition.machine.write_safely(object, :event_transition, transition)
                          run_actions
                          transition
                        else
                          within_transaction do
                            catch(:halt) { run_callbacks(&block) }
                            rollback unless success?
                          end
                          transition
                        end

                results_mutex.with_write_lock { results << result }
              rescue StandardError => e
                # Handle individual transition failures
                rollback
                raise AsyncTransitionError.new(object, [transition.machine], [e.message])
              end
            end
          end

          # Wait for all threads to complete
          threads.each(&:join)
          @success = results.length == length
        end

        success?
      end

      private

      # Override run_actions to be thread-safe when needed
      def run_actions(&block)
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
