# frozen_string_literal: true

require 'test_helper'

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
    %i[alarm_active? alarm_off?].each do |name|
      assert_respond_to @object, name
    end
  end

  def test_should_namespace_event_checks
    %i[can_enable_alarm? can_disable_alarm?].each do |name|
      assert_respond_to @object, name
    end
  end

  def test_should_namespace_event_transition_readers
    %i[enable_alarm_transition disable_alarm_transition].each do |name|
      assert_respond_to @object, name
    end
  end

  def test_should_namespace_events
    %i[enable_alarm disable_alarm].each do |name|
      assert_respond_to @object, name
    end
  end

  def test_should_namespace_bang_events
    %i[enable_alarm! disable_alarm!].each do |name|
      assert_respond_to @object, name
    end
  end
end
