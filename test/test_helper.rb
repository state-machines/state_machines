# frozen_string_literal: true

require 'state_machines'
require_relative '../lib/state_machines/test_helper'
require 'minitest/autorun'
require 'debug' if RUBY_ENGINE == 'ruby'
require 'minitest/reporters'
Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new]

class StateMachinesTest < Minitest::Test
  include StateMachines::TestHelper

  def before_setup
    super
    StateMachines::Integrations.reset
  end
end
