require_relative '../../test_helper'

class MachineWithConflictingHelpersBeforeDefinitionTest < StateMachinesTest
  module Custom
    include StateMachines::Integrations::Base

    def create_with_scope(_name)
      lambda { |_klass, _values| [] }
    end

    def create_without_scope(_name)
      lambda { |_klass, _values| [] }
    end
  end

  def setup
    @original_stderr, $stderr = $stderr, StringIO.new

    StateMachines::Integrations.register(MachineWithConflictingHelpersBeforeDefinitionTest::Custom)

    @superclass = Class.new do
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
    @klass = Class.new(@superclass)
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

  def test_should_output_warning
    expected = [
        'Instance method "state_events"',
        'Instance method "state_transitions"',
        'Instance method "fire_state_event"',
        'Instance method "state_paths"',
        'Class method "human_state_name"',
        'Class method "human_state_event_name"',
        'Instance method "state_name"',
        'Instance method "human_state_name"',
        'Class method "with_state"',
        'Class method "with_states"',
        'Class method "without_state"',
        'Class method "without_states"'
    ].map { |method| "#{method} is already defined in #{@superclass}, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n" }.join

    assert_equal expected, $stderr.string
  end

  def teardown
    $stderr = @original_stderr
  end
end

