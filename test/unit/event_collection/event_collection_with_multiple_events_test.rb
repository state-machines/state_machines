require_relative '../../test_helper'

class EventCollectionWithMultipleEventsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @events = StateMachines::EventCollection.new(@machine)

    @machine.state :first_gear
    @park, @shift_down = @machine.event :park, :shift_down

    @events << @park
    @park.transition first_gear: :parked

    @events << @shift_down
    @shift_down.transition first_gear: :parked

    @machine.events.concat(@events)
  end

  def test_should_only_include_all_valid_events_for_an_object
    object = @klass.new
    object.state = 'first_gear'
    assert_equal [@park, @shift_down], @events.valid_for(object)
  end
end

