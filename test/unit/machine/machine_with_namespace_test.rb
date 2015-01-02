require_relative '../../test_helper'

class MachineWithNamespaceTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, namespace: 'alarm', initial: :active) do
      event :enable do
        transition off: :active
      end

      event :disable do
        transition active: :off
      end
    end
    @object = @klass.new
  end

  def test_should_namespace_state_predicates
    [:alarm_active?, :alarm_off?].each do |name|
      assert @object.respond_to?(name)
    end
  end

  def test_should_namespace_event_checks
    [:can_enable_alarm?, :can_disable_alarm?].each do |name|
      assert @object.respond_to?(name)
    end
  end

  def test_should_namespace_event_transition_readers
    [:enable_alarm_transition, :disable_alarm_transition].each do |name|
      assert @object.respond_to?(name)
    end
  end

  def test_should_namespace_events
    [:enable_alarm, :disable_alarm].each do |name|
      assert @object.respond_to?(name)
    end
  end

  def test_should_namespace_bang_events
    [:enable_alarm!, :disable_alarm!].each do |name|
      assert @object.respond_to?(name)
    end
  end
end

