# frozen_string_literal: true

require 'test_helper'

class STDIORendererTest < Minitest::Test
  def test_draw_machine
    machine = StateMachines::Machine.new(Class.new) do
      state :parked
      state :idling
      event :ignite do
        transition parked: :idling
      end
    end

    io = StringIO.new
    machine.draw(io: io)

    assert_includes(io.string, "Class: ")
    assert_includes(io.string, "States:")
    assert_includes(io.string, "parked")
    assert_includes(io.string, "idling")
    assert_includes(io.string, "Events:")
    assert_includes(io.string, "ignite")
    assert_includes(io.string, "parked => idling")
  end
  def test_draw_machine_with_no_events
    machine = StateMachines::Machine.new(Class.new) do
      state :parked
    end

    io = StringIO.new
    machine.draw(io: io)

    assert_includes(io.string, "Class: ")
    assert_includes(io.string, "States:")
    assert_includes(io.string, "parked")
    assert_includes(io.string, "Events:")
    assert_includes(io.string, "None")
  end

  def test_draw_machine_with_custom_io
    machine = StateMachines::Machine.new(Class.new) do
      state :parked
    end

    io = StringIO.new
    machine.draw(io: io)

    assert_includes(io.string, "Class: ")
    assert_includes(io.string, "States:")
    assert_includes(io.string, "parked")
    assert_includes(io.string, "Events:")
    assert_includes(io.string, "None")
  end

  def test_draw_class
    machine = StateMachines::Machine.new(Class.new) { }
    io = StringIO.new
    machine.renderer.draw_class(machine: machine, io: io)
    assert_includes(io.string, "Class: ")
  end

  def test_draw_states
    machine = StateMachines::Machine.new(Class.new) do
      state :parked
      state :idling
    end
    io = StringIO.new
    machine.renderer.draw_states(machine: machine, io: io)
    assert_includes(io.string, "States:")
    assert_includes(io.string, "parked")
    assert_includes(io.string, "idling")
  end

  def test_draw_event
    machine = StateMachines::Machine.new(Class.new) { }
    event = StateMachines::Event.new(machine, :ignite)
    graph = {}
    io = StringIO.new
    machine.renderer.draw_event(event, graph, options: {}, io: io)
    assert_includes(io.string, "Event: ignite")
  end

  def test_draw_branch
    machine = StateMachines::Machine.new(Class.new) { }
    branch = StateMachines::Branch.new
    graph = {}
    event = StateMachines::Event.new(machine, :ignite)
    io = StringIO.new
    machine.renderer.draw_branch(branch, graph, event, options: {}, io: io)
    assert_includes(io.string, "Branch: ")
  end

  def test_draw_state
    machine = StateMachines::Machine.new(Class.new) { }
    state = StateMachines::State.new(machine, :parked)
    graph = {}
    io = StringIO.new
    machine.renderer.draw_state(state, graph, options: {}, io: io)
    assert_includes(io.string, "State: parked")
  end

  def test_draw_events
    machine = StateMachines::Machine.new(Class.new) do
      state :parked
      state :idling
      event :ignite do
        transition parked: :idling
      end
    end
    io = StringIO.new
    machine.renderer.draw_events(machine: machine, io: io)
    assert_includes(io.string, "Events:")
    assert_includes(io.string, "ignite")
    assert_includes(io.string, "parked => idling")
  end
end