require_relative '../../test_helper'

class MachineWithoutInitializationTest < StateMachinesTest
  def setup
    @klass = Class.new do
      def initialize(attributes = {})
        attributes.each { |attr, value| send("#{attr}=", value) }
        super()
      end
    end

    @machine = StateMachines::Machine.new(@klass, initial: :parked, initialize: false)
  end

  def test_should_not_have_an_initial_state
    object = @klass.new
    assert_nil object.state
  end

  def test_should_still_allow_manual_initialization
    @klass.send(:include, Module.new do
                          def initialize(_attributes = {})
                            super()
                            initialize_state_machines
                          end
                        end)

    object = @klass.new
    assert_equal 'parked', object.state
  end
end
