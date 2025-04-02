# frozen_string_literal: true

module StateMachines
  module STDIORenderer
    def self.draw_machine(machine, **options)
      io = options[:io] || $stdout
      draw_class(machine: machine, io: io)
      draw_states(machine: machine, io: io)
      draw_events(machine: machine, io: io)
    end

    def self.draw_class(machine:, io:)
      io.puts "Class: #{machine.owner_class.name}"
    end

    def self.draw_states(machine:, io:)
      io.puts "  States:"
      if machine.states.to_a.empty?
        io.puts "    - None"
      else
        machine.states.each do |state|
          io.puts "    - #{state.name}"
        end
      end
    end

    def self.draw_events(machine:, io:)
      io.puts "  Events:"
      if machine.events.to_a.empty?
        io.puts "    - None"
      else
        machine.events.each do |event|
          io.puts "    - #{event.name}"
          event.branches.each do |branch|
            branch.state_requirements.each do |requirement|
              io.puts "      - #{requirement[:from].values.join(', ')} => #{requirement[:to].values.join(', ')}"
            end
          end
        end
      end
    end
  end
end