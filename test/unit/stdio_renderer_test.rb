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
    StateMachines::STDIORenderer.draw_machine(machine, io: io)

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
    StateMachines::STDIORenderer.draw_machine(machine, io: io)

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
    StateMachines::STDIORenderer.draw_machine(machine, io: io)

    assert_includes(io.string, "Class: ")
    assert_includes(io.string, "States:")
    assert_includes(io.string, "parked")
    assert_includes(io.string, "Events:")
    assert_includes(io.string, "None")
  end
end