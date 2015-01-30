require_relative '../../test_helper'

class MachineWithConflictingHelpersAfterDefinitionTest < StateMachinesTest
  module Custom
    include StateMachines::Integrations::Base

    def create_with_scope(_name)
      ->(_klass, _values) { [] }
    end

    def create_without_scope(_name)
      ->(_klass, _values) { [] }
    end
  end
  def setup
    @original_stderr, $stderr = $stderr, StringIO.new
    StateMachines::Integrations.register(MachineWithConflictingHelpersAfterDefinitionTest::Custom)
    @klass = Class.new do
      def self.with_state
        :with_state
      end

      def self.with_states
        :with_states
      end

      def self.without_state
        :without_state
      end

      def self.without_states
        :without_states
      end

      def self.human_state_name
        :human_state_name
      end

      def self.human_state_event_name
        :human_state_event_name
      end

      attr_accessor :status

      def state
        'parked'
      end

      def state=(value)
        self.status = value
      end

      def state?
        true
      end

      def state_name
        :parked
      end

      def human_state_name
        'parked'
      end

      def state_events
        [:ignite]
      end

      def state_transitions
        [{ parked: :idling }]
      end

      def state_paths
        [[{ parked: :idling }]]
      end

      def fire_state_event
        true
      end
    end



    @machine = StateMachines::Machine.new(@klass, integration: :custom)
    @machine.state :parked, :idling
    @machine.event :ignite
    @object = @klass.new
  end

  def test_should_not_redefine_singular_with_scope
    assert_equal :with_state, @klass.with_state
  end

  def test_should_not_redefine_plural_with_scope
    assert_equal :with_states, @klass.with_states
  end

  def test_should_not_redefine_singular_without_scope
    assert_equal :without_state, @klass.without_state
  end

  def test_should_not_redefine_plural_without_scope
    assert_equal :without_states, @klass.without_states
  end

  def test_should_not_redefine_human_attribute_name_reader
    assert_equal :human_state_name, @klass.human_state_name
  end

  def test_should_not_redefine_human_event_name_reader
    assert_equal :human_state_event_name, @klass.human_state_event_name
  end

  def test_should_not_redefine_attribute_reader
    assert_equal 'parked', @object.state
  end

  def test_should_not_redefine_attribute_writer
    @object.state = 'parked'
    assert_equal 'parked', @object.status
  end

  def test_should_not_define_attribute_predicate
    assert @object.state?
  end

  def test_should_not_redefine_attribute_name_reader
    assert_equal :parked, @object.state_name
  end

  def test_should_not_redefine_attribute_human_name_reader
    assert_equal 'parked', @object.human_state_name
  end

  def test_should_not_redefine_attribute_events_reader
    assert_equal [:ignite], @object.state_events
  end

  def test_should_not_redefine_attribute_transitions_reader
    assert_equal [{ parked: :idling }], @object.state_transitions
  end

  def test_should_not_redefine_attribute_paths_reader
    assert_equal [[{ parked: :idling }]], @object.state_paths
  end

  def test_should_not_redefine_event_runner
    assert_equal true, @object.fire_state_event
  end

  def test_should_allow_super_chaining
    @klass.class_eval do
      def self.with_state(*states)
        super
      end

      def self.with_states(*states)
        super
      end

      def self.without_state(*states)
        super
      end

      def self.without_states(*states)
        super
      end

      def self.human_state_name(state)
        super
      end

      def self.human_state_event_name(event)
        super
      end

      attr_accessor :status

      def state
        super
      end

      def state=(value)
        super
      end

      def state?(state)
        super
      end

      def state_name
        super
      end

      def human_state_name
        super
      end

      def state_events
        super
      end

      def state_transitions
        super
      end

      def state_paths
        super
      end

      def fire_state_event(event)
        super
      end
    end

    assert_equal [], @klass.with_state
    assert_equal [], @klass.with_states
    assert_equal [], @klass.without_state
    assert_equal [], @klass.without_states
    assert_equal 'parked', @klass.human_state_name(:parked)
    assert_equal 'ignite', @klass.human_state_event_name(:ignite)

    assert_equal nil, @object.state
    @object.state = 'idling'
    assert_equal 'idling', @object.state
    assert_equal nil, @object.status
    assert_equal false, @object.state?(:parked)
    assert_equal :idling, @object.state_name
    assert_equal 'idling', @object.human_state_name
    assert_equal [], @object.state_events
    assert_equal [], @object.state_transitions
    assert_equal [], @object.state_paths
    assert_equal false, @object.fire_state_event(:ignite)
  end

  def test_should_not_output_warning
    assert_equal '', $stderr.string
  end

  def teardown
    $stderr = @original_stderr
    StateMachines::Integrations.reset
  end
end
