# frozen_string_literal: true

require 'test_helper'

class TransitionPerformTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_reader :saved

      def save
        @saved = true
      end
    end

    @machine = StateMachines::Machine.new(@klass, action: :save)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end

  def test_should_run_action_with_true
    @transition.perform(true)

    assert @object.saved
  end

  def test_should_not_run_action_with_false
    @transition.perform(false)

    refute @object.saved
  end

  def test_should_run_action_with_run_action_true
    @transition.perform(run_action: true)

    assert @object.saved
  end

  def test_should_not_run_action_with_run_action_false
    @transition.perform(run_action: false)

    refute @object.saved
  end

  def test_should_run_action_by_default
    @transition.perform

    assert @object.saved
  end
end
