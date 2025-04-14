# frozen_string_literal: true

module StateMachines
  module STDIORenderer
    module_function def draw_machine(machine, io: $stdout)
      draw_class(machine: machine, io: io)
      draw_states(machine: machine, io: io)
      draw_events(machine: machine, io: io)
    end

    module_function def draw_class(machine:, io: $stdout)
      io.puts "Class: #{machine.owner_class.name}"
    end

    module_function def draw_states(machine:, io: $stdout)
      io.puts "  States:"
      if machine.states.to_a.empty?
        io.puts "    - None"
      else
        machine.states.each do |state|
          io.puts "    - #{state.name}"
        end
      end
    end

    module_function def draw_event(event, graph, options: {}, io: $stdout)
      io = io || options[:io] || $stdout
      io.puts "  Event: #{event.name}"
    end

    module_function def draw_branch(branch, graph, event, options: {}, io: $stdout)
      io = io || options[:io] || $stdout
      io.puts "  Branch: #{branch.inspect}"
    end

    module_function def draw_state(state, graph, options: {}, io: $stdout)
      io = io || options[:io] || $stdout
      io.puts "  State: #{state.name}"
    end

    module_function def draw_events(machine:, io: $stdout)
      io.puts "  Events:"
      if machine.events.to_a.empty?
        io.puts "    - None"
      else
        machine.events.each do |event|
          io.puts "    - #{event.name}"
          event.branches.each do |branch|
            branch.state_requirements.each do |requirement|
              out = +"      - "
              out << "#{draw_requirement(requirement[:from])} => #{draw_requirement(requirement[:to])}"
              out << " IF #{branch.if_condition}" if branch.if_condition
              out << " UNLESS #{branch.unless_condition}" if branch.unless_condition
              io.puts out
            end
          end
        end
      end
    end

    module_function def draw_requirement(requirement)
      case requirement
        when StateMachines::BlacklistMatcher
          "ALL EXCEPT #{requirement.values.join(', ')}"
        when StateMachines::AllMatcher
          "ALL"
        when StateMachines::LoopbackMatcher
          "SAME"
        else
          requirement.values.join(', ')
      end
    end
  end
end
