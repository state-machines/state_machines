# frozen_string_literal: true

require 'test_helper'

class StateContextOutOfStateErrorTest < StateMachinesTest
  def setup
    @klass = Class.new do
      state_machine(initial: :parked) do
        event(:ignite) { transition parked: :idling }
        state(:parked) { def speed(gear) = gear }
      end
    end
    @object = @klass.new
    @object.ignite
  end

  def test_should_raise_a_no_method_error
    error = assert_raises(NoMethodError) { @object.speed(2) }

    assert_kind_of StateMachines::InvalidContext, error
  end

  def test_should_describe_the_call
    error = assert_raises(StateMachines::InvalidContext) { @object.speed(2) }

    assert_equal [:speed, [2]], [error.name, error.args]
  end

  def test_should_carry_the_object_as_receiver
    error = assert_raises(StateMachines::InvalidContext) { @object.speed(2) }

    assert_same @object, error.receiver
    assert_same @object, error.object
  end

  def test_should_name_the_state
    error = assert_raises(StateMachines::InvalidContext) { @object.speed(2) }

    assert_equal 'State :idling for :state is not a valid context for calling #speed', error.message
  end
end

class StateContextOutOfStateArgumentsTest < StateMachinesTest
  def setup
    klass = Class.new do
      state_machine(initial: :parked) do
        event(:ignite) { transition parked: :idling }
        state(:parked) { def inspect_item(item, **options) = [item, options] }
      end
    end
    @object = klass.new
    @object.ignite
  end

  def test_should_include_keywords_as_no_method_error_does
    error = assert_raises(StateMachines::InvalidContext) { @object.inspect_item(1, x: 2) }

    assert_equal [1, { x: 2 }], error.args
  end

  def test_should_leave_out_empty_keywords
    error = assert_raises(StateMachines::InvalidContext) { @object.inspect_item(1) }

    assert_equal [1], error.args
  end
end

class StateContextOutOfStateNestedReceiverTest < StateMachinesTest
  def test_should_keep_an_error_raised_for_another_receiver
    inner_class = Class.new do
      state_machine(initial: :parked) do
        event(:ignite) { transition parked: :idling }
        state(:parked) { def probe(number) = number }
      end
    end
    inner = inner_class.new
    inner.ignite
    base = Class.new do
      define_method(:probe) { |n| inner.probe(n) }
    end
    outer_class = Class.new(base) do
      state_machine(initial: :parked) do
        event(:ignite) { transition parked: :idling }
        state(:parked) { def probe(number) = [:outer, number] }
      end
    end
    outer = outer_class.new
    outer.ignite

    error = assert_raises(StateMachines::InvalidContext) { outer.probe(1) }
    assert_same inner, error.receiver
  end
end

class StateContextOutOfStateMethodMissingTest < StateMachinesTest
  def build(claims:)
    Class.new do
      define_method(:method_missing) { |name, *args| name == :speed ? [:missing, *args] : super(name, *args) }
      define_method(:respond_to_missing?) { |name, include_all = false| (claims && name == :speed) || super(name, include_all) }

      state_machine(initial: :parked) do
        event(:ignite) { transition parked: :idling }
        state(:parked) { def speed(gear) = gear }
      end
    end.new.tap(&:ignite)
  end

  def test_should_fall_through_to_a_method_missing_that_claims_it
    assert_equal [:missing, 3], build(claims: true).speed(3)
  end

  def test_should_not_fall_through_to_one_that_does_not
    assert_raises(StateMachines::InvalidContext) { build(claims: false).speed(3) }
  end
end
