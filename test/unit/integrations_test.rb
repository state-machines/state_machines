require 'test_helper'

class IntegrationMatcherTest < MiniTest::Test
  def setup
    superclass = Class.new
    self.class.const_set('Vehicle', superclass)

    @klass = Class.new(superclass)
  end

  def test_should_return_nil_if_no_match_found
    assert_nil StateMachines::Integrations.match(@klass)
  end

  def test_should_return_integration_class_if_match_found
    integration = Module.new do
      include StateMachines::Integrations::Base

      def self.matching_ancestors
        ['IntegrationMatcherTest::Vehicle']
      end
    end
    StateMachines::Integrations.const_set('Custom', integration)

    assert_equal integration, StateMachines::Integrations.match(@klass)
  ensure
    StateMachines::Integrations.send(:remove_const, 'Custom')
  end

  def test_should_return_nil_if_no_match_found_with_ancestors
    assert_nil StateMachines::Integrations.match_ancestors(['IntegrationMatcherTest::Fake'])
  end

  def test_should_return_integration_class_if_match_found_with_ancestors
    integration = Module.new do
      include StateMachines::Integrations::Base

      def self.matching_ancestors
        ['IntegrationMatcherTest::Vehicle']
      end
    end
    StateMachines::Integrations.const_set('Custom', integration)

    assert_equal integration, StateMachines::Integrations.match_ancestors(['IntegrationMatcherTest::Fake', 'IntegrationMatcherTest::Vehicle'])
  ensure
    StateMachines::Integrations.send(:remove_const, 'Custom')
  end

  def teardown
    self.class.send(:remove_const, 'Vehicle')
  end
end

class IntegrationFinderTest < MiniTest::Test
  def test_should_find_base
    assert_equal StateMachines::Integrations::Base, StateMachines::Integrations.find_by_name(:base)
  end

  def test_should_raise_an_exception_if_invalid
    exception = assert_raises(StateMachines::IntegrationNotFound) { StateMachines::Integrations.find_by_name(:invalid) }
    assert_equal ':invalid is an invalid integration', exception.message
  end
end
