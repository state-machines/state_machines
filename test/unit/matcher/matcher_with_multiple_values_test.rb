# frozen_string_literal: true

require 'test_helper'

class MatcherWithMultipleValuesTest < StateMachinesTest
  def setup
    @matcher = StateMachines::Matcher.new(%i[parked idling])
  end

  def test_should_have_values
    assert_equal %i[parked idling], @matcher.values
  end

  def test_should_filter_unknown_values
    assert_equal [:parked], @matcher.filter(%i[parked first_gear])
  end
end
