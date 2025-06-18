# frozen_string_literal: true

require 'test_helper'

class MatcherByDefaultTest < StateMachinesTest
  def setup
    @matcher = StateMachines::Matcher.new
  end

  def test_should_have_no_values
    assert_empty @matcher.values
  end

  def test_should_filter_all_values
    assert_empty @matcher.filter(%i[parked idling])
  end
end
