require_relative '../../test_helper'

class MachinePersistenceTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_accessor :state_event
    end
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @object = @klass.new
  end

  def test_should_allow_reading_state
    assert_equal 'parked', @machine.read(@object, :state)
  end

  def test_should_allow_reading_custom_attributes
    assert_nil @machine.read(@object, :event)

    @object.state_event = 'ignite'
    assert_equal 'ignite', @machine.read(@object, :event)
  end

  def test_should_allow_reading_custom_instance_variables
    @klass.class_eval do
      attr_writer :state_value
    end

    @object.state_value = 1
    assert_raises(NoMethodError) { @machine.read(@object, :value) }
    assert_equal 1, @machine.read(@object, :value, true)
  end

  def test_should_allow_writing_state
    @machine.write(@object, :state, 'idling')
    assert_equal 'idling', @object.state
  end

  def test_should_allow_writing_custom_attributes
    @machine.write(@object, :event, 'ignite')
    assert_equal 'ignite', @object.state_event
  end

  def test_should_allow_writing_custom_instance_variables
    @klass.class_eval do
      attr_reader :state_value
    end

    assert_raises(NoMethodError) { @machine.write(@object, :value, 1) }
    assert_equal 1, @machine.write(@object, :value, 1, true)
    assert_equal 1, @object.state_value
  end
end
