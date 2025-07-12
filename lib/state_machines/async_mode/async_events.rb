# frozen_string_literal: true

module StateMachines
  module AsyncMode
    # Async-aware event firing capabilities using the async gem
    module AsyncEvents
      # Fires an event asynchronously using Async
      # Returns an Async::Task that can be awaited for the result
      #
      # Example:
      #   Async do
      #     task = vehicle.async_fire_event(:ignite)
      #     result = task.wait # => true/false
      #   end
      def async_fire_event(event_name, *args)
        # Find the machine that has this event
        machine = self.class.state_machines.values.find { |m| m.events[event_name] }

        unless machine
          raise ArgumentError, "Event #{event_name} not found in any state machine"
        end

        # Must be called within an Async context
        unless defined?(::Async::Task) && ::Async::Task.current?
          raise RuntimeError, "async_fire_event must be called within an Async context. Use: Async { vehicle.async_fire_event(:event) }"
        end

        Async do
          machine.events[event_name].fire(self, *args)
        end
      end

      # Fires multiple events asynchronously across different state machines
      # Returns an array of Async::Tasks for concurrent execution
      #
      # Example:
      #   Async do
      #     tasks = vehicle.async_fire_events(:ignite, :buy_insurance)
      #     results = tasks.map(&:wait) # => [true, true]
      #   end
      def async_fire_events(*event_names)
        event_names.map { |event_name| async_fire_event(event_name) }
      end

      # Fires an event asynchronously and waits for completion
      # This is a convenience method that creates and waits for the task
      #
      # Example:
      #   result = vehicle.fire_event_async(:ignite) # => true/false
      def fire_event_async(event_name, *args)
        raise NoMethodError, "undefined method `fire_event_async' for #{self}" unless has_async_machines?
        # Find the machine that has this event
        machine = self.class.state_machines.values.find { |m| m.events[event_name] }

        unless machine
          raise ArgumentError, "Event #{event_name} not found in any state machine"
        end

        if defined?(::Async::Task) && ::Async::Task.current?
          # Already in async context, just fire directly
          machine.events[event_name].fire(self, *args)
        else
          # Create async context and wait for result
          Async do
            machine.events[event_name].fire(self, *args)
          end.wait
        end
      end

      # Fires multiple events asynchronously and waits for all completions
      # Returns results in the same order as the input events
      #
      # Example:
      #   results = vehicle.fire_events_async(:ignite, :buy_insurance) # => [true, true]
      def fire_events_async(*event_names)
        raise NoMethodError, "undefined method `fire_events_async' for #{self}" unless has_async_machines?
        if defined?(::Async::Task) && ::Async::Task.current?
          # Already in async context, run concurrently
          tasks = event_names.map { |event_name| async_fire_event(event_name) }
          tasks.map(&:wait)
        else
          # Create async context and run concurrently
          Async do
            tasks = event_names.map { |event_name| async_fire_event(event_name) }
            tasks.map(&:wait)
          end.wait
        end
      end

      # Fires an event asynchronously using Async and raises exception on failure
      # Returns an Async::Task that raises StateMachines::InvalidTransition when awaited
      #
      # Example:
      #   Async do
      #     begin
      #       task = vehicle.async_fire_event!(:ignite)
      #       result = task.wait
      #       puts "Event fired successfully!"
      #     rescue StateMachines::InvalidTransition => e
      #       puts "Transition failed: #{e.message}"
      #     end
      #   end
      def async_fire_event!(event_name, *args)
        # Find the machine that has this event
        machine = self.class.state_machines.values.find { |m| m.events[event_name] }

        unless machine
          raise ArgumentError, "Event #{event_name} not found in any state machine"
        end

        # Must be called within an Async context
        unless defined?(::Async::Task) && ::Async::Task.current?
          raise RuntimeError, "async_fire_event! must be called within an Async context. Use: Async { vehicle.async_fire_event!(:event) }"
        end

        Async do
          # Use the bang version which raises exceptions on failure
          machine.events[event_name].fire(self, *args) || raise(StateMachines::InvalidTransition.new(self, machine, event_name))
        end
      end

      # Fires an event asynchronously and waits for result, raising exceptions on failure
      # This is a convenience method that creates and waits for the task
      #
      # Example:
      #   begin
      #     result = vehicle.fire_event_async!(:ignite)
      #     puts "Event fired successfully!"
      #   rescue StateMachines::InvalidTransition => e
      #     puts "Transition failed: #{e.message}"
      #   end
      def fire_event_async!(event_name, *args)
        raise NoMethodError, "undefined method `fire_event_async!' for #{self}" unless has_async_machines?
        # Find the machine that has this event
        machine = self.class.state_machines.values.find { |m| m.events[event_name] }

        unless machine
          raise ArgumentError, "Event #{event_name} not found in any state machine"
        end

        if defined?(::Async::Task) && ::Async::Task.current?
          # Already in async context, just fire directly with bang behavior
          machine.events[event_name].fire(self, *args) || raise(StateMachines::InvalidTransition.new(self, machine, event_name))
        else
          # Create async context and wait for result (may raise exception)
          Async do
            machine.events[event_name].fire(self, *args) || raise(StateMachines::InvalidTransition.new(self, machine, event_name))
          end.wait
        end
      end

      # Dynamically handle individual event async methods
      # This provides launch_async, launch_async!, arm_weapons_async, etc.
      def method_missing(method_name, *args, **kwargs, &block)
        method_str = method_name.to_s

        # Check if this is an async event method
        if method_str.end_with?('_async!')
          # Remove the _async! suffix to get the base event method
          base_method = method_str.chomp('_async!').to_sym

          # Check if the base method exists and this machine is async-enabled
          if respond_to?(base_method) && async_method_for_event?(base_method)
            return handle_individual_event_async_bang(base_method, *args, **kwargs)
          end
        elsif method_str.end_with?('_async')
          # Remove the _async suffix to get the base event method
          base_method = method_str.chomp('_async').to_sym

          # Check if the base method exists and this machine is async-enabled
          if respond_to?(base_method) && async_method_for_event?(base_method)
            return handle_individual_event_async(base_method, *args, **kwargs)
          end
        end

        # If not an async method, call the original method_missing
        super
      end

      # Check if we should respond to async methods for this event
      def respond_to_missing?(method_name, include_private = false)
        # Only provide async methods if this object has async-enabled machines
        return super unless has_async_machines?

        method_str = method_name.to_s

        if method_str.end_with?('_async!') || method_str.end_with?('_async')
          base_method = method_str.chomp('_async!').chomp('_async').to_sym
          return respond_to?(base_method) && async_method_for_event?(base_method)
        end

        super
      end

      # Check if this object has any async-enabled state machines
      def has_async_machines?
        self.class.state_machines.any? { |name, machine| machine.async_mode_enabled? }
      end

      private

      # Check if this event method should have async versions
      def async_method_for_event?(event_method)
        # Find which machine contains this event
        self.class.state_machines.each do |name, machine|
          if machine.async_mode_enabled?
            # Check if this event method belongs to this machine
            machine.events.each do |event|
              qualified_name = event.qualified_name
              if qualified_name.to_sym == event_method || "#{qualified_name}!".to_sym == event_method
                return true
              end
            end
          end
        end
        false
      end

      # Handle individual event async methods (returns task)
      def handle_individual_event_async(event_method, *args, **kwargs)

        unless defined?(::Async::Task) && ::Async::Task.current?
          raise RuntimeError, "#{event_method}_async must be called within an Async context"
        end

        Async do
          send(event_method, *args, **kwargs)
        end
      end

      # Handle individual event async bang methods (returns task, raises on failure)
      def handle_individual_event_async_bang(event_method, *args, **kwargs)
        # Extract event name from method and use bang version
        bang_method = "#{event_method}!".to_sym

        unless defined?(::Async::Task) && ::Async::Task.current?
          raise RuntimeError, "#{event_method}_async! must be called within an Async context"
        end

        Async do
          send(bang_method, *args, **kwargs)
        end
      end

      # Extract event name from method name, handling namespaced events
      def extract_event_name(method_name)
        method_str = method_name.to_s

        # Find the machine and event for this method
        self.class.state_machines.each do |name, machine|
          machine.events.each do |event|
            qualified_name = event.qualified_name
            if qualified_name.to_s == method_str || "#{qualified_name}!".to_s == method_str
              return event.name
            end
          end
        end

        # Fallback: assume the method name is the event name
        method_str.chomp('!').to_sym
      end

      public

      # Fires multiple events concurrently within an async context
      # This method should be called from within an Async block
      #
      # Example:
      #   Async do
      #     results = vehicle.fire_events_concurrent(:ignite, :buy_insurance)
      #   end
      def fire_events_concurrent(*event_names)
        unless defined?(::Async::Task) && ::Async::Task.current?
          raise RuntimeError, "fire_events_concurrent must be called within an Async context"
        end

        tasks = async_fire_events(*event_names)
        tasks.map(&:wait)
      end
    end
  end
end
