# frozen_string_literal: true

require 'test_helper'

class EventWithBranchCallbacksTest < StateMachinesTest
  class Vehicle
    attr_accessor :fuelled, :save_result, :halt_in
    attr_reader :log

    def initialize
      @log = []
      @fuelled = true
      @save_result = true
      super
    end

    def save
      @log << :save
      save_result
    end

    %i[machine_before machine_after machine_failure branch_before branch_after other_after].each do |name|
      define_method(name) do
        @log << name
        throw :halt if halt_in == name
      end
    end

    def machine_around(*)
      @log << :machine_around_in
      yield
      @log << :machine_around_out
    end

    def branch_around(*)
      @log << :branch_around_in
      yield unless halt_in == :branch_around
      @log << :branch_around_out
    end

    state_machine initial: :parked, action: :save do
      before_transition :machine_before
      around_transition :machine_around
      after_transition :machine_after
      after_failure :machine_failure

      event :ignite do
        transition parked: :idling, unless: :fuelled, after: :other_after
        transition parked: :idling, before: :branch_before, around: :branch_around, after: :branch_after
      end
    end
  end

  def setup
    @vehicle = Vehicle.new
  end

  def test_should_wrap_branch_callbacks_closest_to_the_change
    assert @vehicle.ignite
    assert_equal %i[machine_before machine_around_in branch_before branch_around_in save
                    branch_around_out machine_around_out branch_after machine_after], @vehicle.log
  end

  def test_should_run_only_the_selected_branch
    @vehicle.fuelled = false
    @vehicle.ignite

    assert_includes @vehicle.log, :other_after
    refute_includes @vehicle.log, :branch_before
  end

  def test_should_not_run_branch_afters_when_the_action_fails
    @vehicle.save_result = false

    refute @vehicle.ignite
    refute_includes @vehicle.log, :branch_after
    assert_equal :machine_failure, @vehicle.log.last
  end

  def test_should_halt_from_a_branch_before
    @vehicle.halt_in = :branch_before

    refute @vehicle.ignite
    assert_equal 'parked', @vehicle.state
    refute_includes @vehicle.log, :save
  end

  def test_should_record_the_halt_as_the_refusal
    @vehicle.halt_in = :branch_before
    @vehicle.ignite

    assert_equal :halted, @vehicle.ignite_refusal
  end

  def test_should_halt_from_a_branch_around_that_does_not_yield
    @vehicle.halt_in = :branch_around

    refute @vehicle.ignite
    assert_equal 'parked', @vehicle.state
    refute_includes @vehicle.log, :save
  end

  def test_should_stop_the_after_chain_when_a_branch_after_halts
    @vehicle.halt_in = :branch_after

    assert @vehicle.ignite
    assert_equal 'idling', @vehicle.state
    refute_includes @vehicle.log, :machine_after
  end
end

class EventWithBranchCallbackFormsTest < StateMachinesTest
  def define(&)
    klass = Class.new { attr_accessor :log }
    StateMachines::Machine.new(klass, initial: :parked, &)
    klass
  end

  def branch(klass, event = :ignite)
    klass.state_machine.events[event].branches.first
  end

  def test_should_expose_callbacks_on_the_branch_in_given_order
    audit = ->(_vehicle) {}
    klass = define { event(:ignite) { transition parked: :idling, after: [:log_it, audit], before: 'check' } }
    callbacks = branch(klass).callbacks

    assert_predicate callbacks, :frozen?
    assert_equal %i[after before], callbacks.map(&:type)
    assert_equal [[:log_it, audit], ['check']], callbacks.map(&:callables)
  end

  def test_should_accept_explicit_from_and_to
    klass = define { event(:ignite) { transition from: :parked, to: :idling, after: :log_it } }

    assert_equal [:after], branch(klass).callbacks.map(&:type)
    assert_equal %i[parked idling], klass.state_machine.states.map(&:name)
  end

  def test_should_have_no_callbacks_without_them
    klass = define { event(:ignite) { transition parked: :idling } }

    assert_empty branch(klass).callbacks
  end

  def test_should_run_a_method_object
    klass = define { event(:ignite) { transition parked: :idling } }
    log = []
    callback = log.method(:<<)
    klass.state_machine.event(:park) { transition idling: :parked, after: callback }
    vehicle = klass.new
    vehicle.ignite
    vehicle.park

    assert_equal [vehicle], log
  end

  def test_should_bind_procs_to_the_object
    StateMachines::Callback.bind_to_object = true
    klass = define { event(:ignite) { transition parked: :idling, after: -> { self.log = :bound } } }
    vehicle = klass.new
    vehicle.ignite

    assert_equal :bound, vehicle.log
  ensure
    StateMachines::Callback.bind_to_object = false
  end

  def test_should_use_the_machine_terminator
    machine_class = Class.new(StateMachines::Machine) do
      private

      def callback_terminator
        ->(result) { result == false }
      end
    end
    klass = Class.new { def deny = false } # rubocop:disable Naming/PredicateMethod
    machine_class.new(klass, initial: :parked) { event(:ignite) { transition parked: :idling, before: :deny } }
    vehicle = klass.new

    refute vehicle.ignite
    assert_equal 'parked', vehicle.state
  end
end

class EventWithReservedTransitionKeysTest < StateMachinesTest
  def define(&)
    StateMachines::Machine.new(Class.new, initial: :parked, &)
  end

  def test_should_refuse_do
    error = assert_raises(ArgumentError) { define { event(:ignite) { transition parked: :idling, do: :log_it } } }
    assert_equal 'transition does not take do:; use after: (or before:/around:)', error.message
  end

  def test_should_not_create_states_from_do
    assert_raises(ArgumentError) { define { event(:ignite) { transition parked: :idling, do: :log_it } } }
  end

  def test_should_explain_a_state_named_after
    error = assert_raises(ArgumentError) { define { event(:ignite) { transition after: :parked } } }
    assert_equal 'after: is reserved in transition for a branch callback; ' \
                 'to transition from a state named :after, write `transition from: :after, to: :parked`', error.message
  end

  def test_should_explain_callbacks_with_only_guards
    error = assert_raises(ArgumentError) { define { event(:ignite) { transition after: :finish, if: :okay? } } }
    assert_match(/write `transition from: :after, to: :finish`/, error.message)
  end

  def test_should_read_a_callback_naming_a_state_as_a_callback
    machine = define do
      state :audit
      event(:ignite) { transition from: :parked, to: :idling, after: :audit }
    end

    assert_equal [[:audit]], machine.events[:ignite].branches.first.callbacks.map(&:callables)
  end

  def test_should_not_depend_on_state_declaration_order
    machine = define do
      event(:ignite) { transition parked: :idling, after: :audit }
      state :audit
    end

    assert_equal [[:audit]], machine.events[:ignite].branches.first.callbacks.map(&:callables)
  end

  def test_should_refuse_a_state_matcher_as_callback
    error = assert_raises(ArgumentError) { define { event(:ignite) { transition parked: :idling, around: same } } }
    assert_match(/around: takes method names/, error.message)
  end

  def test_should_refuse_an_empty_callback_list
    error = assert_raises(ArgumentError) { define { event(:ignite) { transition parked: :idling, after: [] } } }
    assert_equal 'after: needs at least one method name, Proc or Method', error.message
  end

  def test_should_refuse_other_values
    error = assert_raises(ArgumentError) { define { event(:ignite) { transition parked: :idling, after: 42 } } }
    assert_equal 'after: takes method names (Symbol/String), Procs or Methods, not 42', error.message
  end

  def test_should_allow_a_state_named_after_through_from_and_to
    machine = define { event(:ignite) { transition from: :after, to: :parked } }

    assert_equal %i[after parked], machine.states.map(&:name)
  end
end

class EventWithBranchCallbackAssertionsTest < StateMachinesTest
  def setup
    klass = Class.new do
      state_machine(initial: :parked) do
        event(:ignite) { transition parked: :idling, if: :fuelled?, before: :check, around: :wrap, after: :log_it }
      end
    end
    @machine = klass.state_machine
  end

  def test_should_see_a_branch_before
    assert_before_transition(@machine, on: :ignite, from: :parked, to: :idling, do: :check, if: :fuelled?)
  end

  def test_should_see_a_branch_around_as_before
    assert_before_transition(@machine, on: :ignite, do: :wrap)
  end

  def test_should_see_a_branch_after
    assert_after_transition(@machine, from: :parked, do: :log_it)
  end

  def test_should_match_against_the_branch
    assert_raises(Minitest::Assertion) { assert_after_transition(@machine, from: :idling, do: :log_it) }
  end

  def test_should_keep_types_apart
    assert_raises(Minitest::Assertion) { assert_after_transition(@machine, on: :ignite, do: :check) }
  end
end

class StateContextWithBranchCallbacksTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_reader :log

      def initialize
        @log = []
        super
      end

      def log_ignition = @log << :ignition
      def check = @log << :check

      state_machine(initial: :parked) do
        state :parked do
          transition to: :idling, on: :ignite, before: :check, after: :log_ignition
        end
      end
    end
  end

  def test_should_run_them_for_the_state_transition
    vehicle = @klass.new
    vehicle.ignite

    assert_equal %i[check ignition], vehicle.log
  end

  def test_should_keep_them_on_the_branch
    branch = @klass.state_machine.events[:ignite].branches.first

    assert_equal %i[before after], branch.callbacks.map(&:type)
  end

  def test_should_explain_do
    error = assert_raises(ArgumentError) do
      Class.new { state_machine(initial: :parked) { state(:parked) { transition to: :idling, on: :ignite, do: :log } } }
    end
    assert_equal 'transition does not take do:; use after: (or before:/around:)', error.message
  end
end
