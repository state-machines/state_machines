# frozen_string_literal: true

require 'test_helper'

# Options an extension gem provides fail loudly when the gem is not loaded,
# and an extension plugs reopenable options in through #reopen_options and
# #reopen.
class MachineWithExtensionOptionsTest < StateMachinesTest
  ASYNC_MISSING = /The :async state machine option is provided by the state_machines-async gem, which is not loaded; add it to your Gemfile and require 'state_machines-async'/

  # Adds a reopenable :beacon option, the way an extension adds its own
  module Beacon
    def reopen_options
      super + %i[beacon]
    end

    def reopen(options)
      super
      @beacon = options[:beacon] if options.include?(:beacon)
    end
  end

  def setup
    @klass = Class.new
  end

  def test_should_name_the_gem_when_async_is_given_on_creation
    error = assert_raises(ArgumentError) { @klass.state_machine(:status, async: true) }

    assert_match ASYNC_MISSING, error.message
    refute @klass.respond_to?(:state_machines) && @klass.state_machines.key?(:status)
  end

  def test_should_name_the_gem_even_when_async_is_false
    error = assert_raises(ArgumentError) { StateMachines::Machine.new(@klass, async: false) }

    assert_match ASYNC_MISSING, error.message
  end

  def test_should_name_the_gem_when_async_is_given_on_reopening
    @klass.state_machine(:status, initial: :parked)

    error = assert_raises(ArgumentError) { @klass.state_machine(:status, async: true) }

    assert_match ASYNC_MISSING, error.message
  end

  def test_should_name_the_gem_when_async_is_given_on_reopening_in_a_subclass
    @klass.state_machine(:status, initial: :parked)
    subclass = Class.new(@klass)

    error = assert_raises(ArgumentError) { subclass.state_machine(:status, async: true) }

    assert_match ASYNC_MISSING, error.message
    assert_same @klass.state_machine(:status), subclass.state_machine(:status)
  end

  def test_should_still_report_other_unknown_options_as_unknown
    error = assert_raises(ArgumentError) { StateMachines::Machine.new(@klass, turbo: true) }

    assert_match(/Unknown key: :turbo/, error.message)
  end

  def test_should_accept_only_initial_on_reopening_by_default
    machine = StateMachines::Machine.new(@klass)

    assert_equal %i[initial], machine.reopen_options
  end

  def test_should_not_claim_transitions_by_default
    refute_predicate StateMachines::Machine.new(@klass), :claims_transitions?
  end

  def test_should_apply_an_option_an_extension_makes_reopenable
    machine = StateMachines::Machine.new(@klass, initial: :parked)
    machine.extend(Beacon)

    StateMachines::Machine.find_or_create(@klass, beacon: :lit)

    assert_equal :lit, machine.instance_variable_get(:@beacon)
  end

  def test_should_list_the_reopenable_options_when_refusing_one
    StateMachines::Machine.new(@klass).extend(Beacon)

    error = assert_raises(ArgumentError) { StateMachines::Machine.find_or_create(@klass, attribute: :status) }

    assert_match(/reopening it accepts only :initial, :beacon\z/, error.message)
  end

  def test_should_apply_a_reopenable_option_to_the_copy_in_a_subclass
    machine = StateMachines::Machine.new(@klass, initial: :parked)
    machine.extend(Beacon)
    subclass = Class.new(@klass)

    copy = StateMachines::Machine.find_or_create(subclass, beacon: :lit)

    refute_same machine, copy
    assert_equal :lit, copy.instance_variable_get(:@beacon)
    assert_nil machine.instance_variable_get(:@beacon)
  end
end
