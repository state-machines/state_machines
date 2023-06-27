require 'test_helper'

class EventStringCollectionTest < StateMachinesTest
  def setup
    machine = StateMachines::Machine.new(Class.new, namespace: 'alarm')
    @events = StateMachines::EventCollection.new(machine)

    @events << @open = StateMachines::Event.new(machine, 'enable')
    machine.events.concat(@events)
  end

  def test_should_index_by_name
    assert_equal @open, @events['enable', :name]
  end

  def test_should_index_by_name_by_default
    assert_equal @open, @events['enable']
  end

  def test_should_index_by_symbol_name
    assert_equal @open, @events[:enable]
  end

  def test_should_index_by_qualified_name
    assert_equal @open, @events['enable_alarm', :qualified_name]
  end

  def test_should_index_by_symbol_qualified_name
    assert_equal @open, @events[:enable_alarm, :qualified_name]
  end
end
