# frozen_string_literal: true

require 'test_helper'

# Finding a state by value must agree with State#matches? (==): only names are
# found by their string form.
class StateCollectionValueLookupTest < StateMachinesTest
  def setup
    @klass = Class.new { attr_accessor :state }
    @machine = StateMachines::Machine.new(@klass, initial: :on) do
      state :on, value: true
      state :off, value: false
      state :one, value: 1
      state :parked
    end
    @states = @machine.states
    @object = @klass.new
  end

  def test_should_find_values_by_themselves
    assert_same @states[:on], @states[true, :value]
    assert_same @states[:off], @states[false, :value]
    assert_same @states[:one], @states[1, :value]
  end

  def test_should_not_find_a_boolean_value_by_its_string
    assert_nil @states['true', :value]
    assert_nil @states['false', :value]
  end

  def test_should_not_find_an_integer_value_by_its_string
    assert_nil @states['1', :value]
    assert_nil @states[:'1', :value]
  end

  def test_should_not_find_a_string_value_by_its_symbol
    assert_same @states[:parked], @states['parked', :value]
    assert_nil @states[:parked, :value]
  end

  def test_should_raise_fetching_a_value_by_its_string
    assert_raises(IndexError) { @states.fetch('true', :value) }
  end

  def test_should_still_find_names_by_their_string
    assert_same @states[:parked], @states['parked']
    assert_same @states[:parked], @states['parked', :qualified_name]
  end

  def test_should_not_match_a_string_attribute_to_a_boolean_state
    @object.state = 'true'

    assert_nil @states.match(@object)
    assert_raises(ArgumentError) { @states.match!(@object) }
  end

  def test_should_not_match_a_string_attribute_to_an_integer_state
    @object.state = '1'

    assert_nil @states.match(@object)
  end

  def test_should_match_an_equal_value_of_another_class
    @object.state = 1.0

    assert_same @states[:one], @states.match(@object)
  end

  def test_should_agree_with_matches_for_every_value
    [true, false, 1, 1.0, 'true', 'false', '1', 'parked', :parked, nil].each do |value|
      @object.state = value

      # Arrays: Minitest refuses a bare nil expectation
      assert_equal [@states.find { |state| state.matches?(value) }], [@states.match(@object)], value.inspect
    end
  end
end

class StateCollectionValueLookupWithMatcherTest < StateMachinesTest
  def setup
    @klass = Class.new { attr_accessor :state }
    @machine = StateMachines::Machine.new(@klass, initial: :parked) do
      state :parked, if: ->(value) { value == 'P' }
    end
    @object = @klass.new
  end

  def test_should_not_match_an_indexed_value_the_matcher_rejects
    @object.state = 'parked'

    assert_nil @machine.states.match(@object)
  end

  def test_should_match_a_value_the_matcher_accepts
    @object.state = 'P'

    assert_same @machine.states[:parked], @machine.states.match(@object)
  end
end

class StateCollectionValueLookupWithStatefulMatcherTest < StateMachinesTest
  def test_should_ask_an_indexed_matcher_once
    calls = 0
    klass = Class.new { attr_accessor :state }
    machine = StateMachines::Machine.new(klass, initial: :parked) do
      state :idle, if: lambda { |_value|
        calls += 1
        calls == 2
      }
    end
    object = klass.new
    object.state = 'idle'

    assert_nil machine.states.match(object)
    assert_equal 1, calls
  end
end
