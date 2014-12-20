require 'test_helper'

class StateByDefaultTest < MiniTest::Test
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @machine.states << @state = StateMachines::State.new(@machine, :parked)
  end

  def test_should_have_a_machine
    assert_equal @machine, @state.machine
  end

  def test_should_have_a_name
    assert_equal :parked, @state.name
  end

  def test_should_have_a_qualified_name
    assert_equal :parked, @state.qualified_name
  end

  def test_should_have_a_human_name
    assert_equal 'parked', @state.human_name
  end

  def test_should_use_stringify_the_name_as_the_value
    assert_equal 'parked', @state.value
  end

  def test_should_not_be_initial
    assert !@state.initial
  end

  def test_should_not_have_a_matcher
    assert_nil @state.matcher
  end

  def test_should_not_have_any_methods
    expected = {}
    assert_equal expected, @state.context_methods
  end
end

class StateTest < MiniTest::Test
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @machine.states << @state = StateMachines::State.new(@machine, :parked)
  end

  def test_should_raise_exception_if_invalid_option_specified
    exception = assert_raises(ArgumentError) { StateMachines::State.new(@machine, :parked, invalid: true) }
    assert_equal 'Unknown key: :invalid. Valid keys are: :initial, :value, :cache, :if, :human_name', exception.message
  end

  def test_should_allow_changing_machine
    new_machine = StateMachines::Machine.new(Class.new)
    @state.machine = new_machine
    assert_equal new_machine, @state.machine
  end

  def test_should_allow_changing_value
    @state.value = 1
    assert_equal 1, @state.value
  end

  def test_should_allow_changing_initial
    @state.initial = true
    assert @state.initial
  end

  def test_should_allow_changing_matcher
    matcher = lambda {}
    @state.matcher = matcher
    assert_equal matcher, @state.matcher
  end

  def test_should_allow_changing_human_name
    @state.human_name = 'stopped'
    assert_equal 'stopped', @state.human_name
  end

  def test_should_use_pretty_inspect
    assert_equal '#<StateMachines::State name=:parked value="parked" initial=false>', @state.inspect
  end
end

class StateWithoutNameTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, nil)
  end

  def test_should_have_a_nil_name
    assert_nil @state.name
  end

  def test_should_have_a_nil_qualified_name
    assert_nil @state.qualified_name
  end

  def test_should_have_an_empty_human_name
    assert_equal 'nil', @state.human_name
  end

  def test_should_have_a_nil_value
    assert_nil @state.value
  end

  def test_should_not_redefine_nil_predicate
    object = @klass.new
    assert !object.nil?
    assert !object.respond_to?('?')
  end

  def test_should_have_a_description
    assert_equal 'nil', @state.description
  end

  def test_should_have_a_description_using_human_name
    assert_equal 'nil', @state.description(human_name: true)
  end
end

class StateWithNameTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, :parked)
  end

  def test_should_have_a_name
    assert_equal :parked, @state.name
  end

  def test_should_have_a_qualified_name
    assert_equal :parked, @state.name
  end

  def test_should_have_a_human_name
    assert_equal 'parked', @state.human_name
  end

  def test_should_use_stringify_the_name_as_the_value
    assert_equal 'parked', @state.value
  end

  def test_should_match_stringified_name
    assert @state.matches?('parked')
    assert !@state.matches?('idling')
  end

  def test_should_not_include_value_in_description
    assert_equal 'parked', @state.description
  end

  def test_should_allow_using_human_name_in_description
    @state.human_name = 'Parked'
    assert_equal 'Parked', @state.description(human_name: true)
  end

  def test_should_define_predicate
    assert @klass.new.respond_to?(:parked?)
  end
end

class StateWithNilValueTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, :parked, value: nil)
  end

  def test_should_have_a_name
    assert_equal :parked, @state.name
  end

  def test_should_have_a_nil_value
    assert_nil @state.value
  end

  def test_should_match_nil_values
    assert @state.matches?(nil)
  end

  def test_should_have_a_description
    assert_equal 'parked (nil)', @state.description
  end

  def test_should_have_a_description_with_human_name
    @state.human_name = 'Parked'
    assert_equal 'Parked (nil)', @state.description(human_name: true)
  end

  def test_should_define_predicate
    object = @klass.new
    assert object.respond_to?(:parked?)
  end
end

class StateWithSymbolicValueTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, :parked, value: :parked)
  end

  def test_should_use_custom_value
    assert_equal :parked, @state.value
  end

  def test_should_not_include_value_in_description
    assert_equal 'parked', @state.description
  end

  def test_should_allow_human_name_in_description
    @state.human_name = 'Parked'
    assert_equal 'Parked', @state.description(human_name: true)
  end

  def test_should_match_symbolic_value
    assert @state.matches?(:parked)
    assert !@state.matches?('parked')
  end

  def test_should_define_predicate
    object = @klass.new
    assert object.respond_to?(:parked?)
  end
end

class StateWithIntegerValueTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, :parked, value: 1)
  end

  def test_should_use_custom_value
    assert_equal 1, @state.value
  end

  def test_should_include_value_in_description
    assert_equal 'parked (1)', @state.description
  end

  def test_should_allow_human_name_in_description
    @state.human_name = 'Parked'
    assert_equal 'Parked (1)', @state.description(human_name: true)
  end

  def test_should_match_integer_value
    assert @state.matches?(1)
    assert !@state.matches?(2)
  end

  def test_should_define_predicate
    object = @klass.new
    assert object.respond_to?(:parked?)
  end
end

class StateWithLambdaValueTest < MiniTest::Test
  def setup
    @klass = Class.new
    @args = nil
    @machine = StateMachines::Machine.new(@klass)
    @value = lambda { |*args| @args = args; :parked }
    @machine.states << @state = StateMachines::State.new(@machine, :parked, value: @value)
  end

  def test_should_use_evaluated_value_by_default
    assert_equal :parked, @state.value
  end

  def test_should_allow_access_to_original_value
    assert_equal @value, @state.value(false)
  end

  def test_should_include_masked_value_in_description
    assert_equal 'parked (*)', @state.description
  end

  def test_should_not_pass_in_any_arguments
    @state.value
    assert_equal [], @args
  end

  def test_should_define_predicate
    object = @klass.new
    assert object.respond_to?(:parked?)
  end

  def test_should_match_evaluated_value
    assert @state.matches?(:parked)
  end
end

class StateWithCachedLambdaValueTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @dynamic_value = lambda { 'value' }
    @machine.states << @state = StateMachines::State.new(@machine, :parked, value: @dynamic_value, cache: true)
  end

  def test_should_be_caching
    assert @state.cache
  end

  def test_should_evaluate_value
    assert_equal 'value', @state.value
  end

  def test_should_only_evaluate_value_once
    value = @state.value
    assert_same value, @state.value
  end

  def test_should_update_value_index_for_state_collection
    @state.value
    assert_equal @state, @machine.states['value', :value]
    assert_nil @machine.states[@dynamic_value, :value]
  end
end

class StateWithoutCachedLambdaValueTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @dynamic_value = lambda { 'value' }
    @machine.states << @state = StateMachines::State.new(@machine, :parked, value: @dynamic_value)
  end

  def test_should_not_be_caching
    assert !@state.cache
  end

  def test_should_evaluate_value_each_time
    value = @state.value
    refute_same value, @state.value
  end

  def test_should_not_update_value_index_for_state_collection
    @state.value
    assert_nil @machine.states['value', :value]
    assert_equal @state, @machine.states[@dynamic_value, :value]
  end
end

class StateWithMatcherTest < MiniTest::Test
  def setup
    @klass = Class.new
    @args = nil
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, :parked, if: lambda { |value| value == 1 })
  end

  def test_should_not_match_actual_value
    assert !@state.matches?('parked')
  end

  def test_should_match_evaluated_block
    assert @state.matches?(1)
  end
end

class StateWithHumanNameTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, :parked, human_name: 'stopped')
  end

  def test_should_use_custom_human_name
    assert_equal 'stopped', @state.human_name
  end
end

class StateWithDynamicHumanNameTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, :parked, human_name: lambda { |_state, object| ['stopped', object] })
  end

  def test_should_use_custom_human_name
    human_name, klass = @state.human_name
    assert_equal 'stopped', human_name
    assert_equal @klass, klass
  end

  def test_should_allow_custom_class_to_be_passed_through
    human_name, klass = @state.human_name(1)
    assert_equal 'stopped', human_name
    assert_equal 1, klass
  end

  def test_should_not_cache_value
    refute_same @state.human_name, @state.human_name
  end
end

class StateInitialTest < MiniTest::Test
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @machine.states << @state = StateMachines::State.new(@machine, :parked, initial: true)
  end

  def test_should_be_initial
    assert @state.initial
    assert @state.initial?
  end
end

class StateNotInitialTest < MiniTest::Test
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @machine.states << @state = StateMachines::State.new(@machine, :parked, initial: false)
  end

  def test_should_not_be_initial
    assert !@state.initial
    assert !@state.initial?
  end
end

class StateFinalTest < MiniTest::Test
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @machine.states << @state = StateMachines::State.new(@machine, :parked)
  end

  def test_should_be_final_without_input_transitions
    assert @state.final?
  end

  def test_should_be_final_with_input_transitions
    @machine.event :park do
      transition idling: :parked
    end

    assert @state.final?
  end

  def test_should_be_final_with_loopback
    @machine.event :ignite do
      transition parked: same
    end

    assert @state.final?
  end
end

class StateNotFinalTest < MiniTest::Test
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @machine.states << @state = StateMachines::State.new(@machine, :parked)
  end

  def test_should_not_be_final_with_outgoing_whitelist_transitions
    @machine.event :ignite do
      transition parked: :idling
    end

    assert !@state.final?
  end

  def test_should_not_be_final_with_outgoing_all_transitions
    @machine.event :ignite do
      transition all => :idling
    end

    assert !@state.final?
  end

  def test_should_not_be_final_with_outgoing_blacklist_transitions
    @machine.event :ignite do
      transition all - :first_gear => :idling
    end

    assert !@state.final?
  end
end

class StateWithConflictingHelpersBeforeDefinitionTest < MiniTest::Test
  def setup
    require 'stringio'
    @original_stderr, $stderr = $stderr, StringIO.new

    @superclass = Class.new do
      def parked?
        0
      end
    end
    @klass = Class.new(@superclass)
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked
    @object = @klass.new
  end

  def test_should_not_override_state_predicate
    assert_equal 0, @object.parked?
  end

  def test_should_output_warning
    assert_equal "Instance method \"parked?\" is already defined in #{@superclass}, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string
  end

  def teardown
    $stderr = @original_stderr
  end
end

class StateWithConflictingHelpersAfterDefinitionTest < MiniTest::Test
  def setup
    require 'stringio'
    @original_stderr, $stderr = $stderr, StringIO.new

    @klass = Class.new do
      def parked?
        0
      end
    end
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked
    @object = @klass.new
  end

  def test_should_not_override_state_predicate
    assert_equal 0, @object.parked?
  end

  def test_should_still_allow_super_chaining
    @klass.class_eval do
      def parked?
        super
      end
    end

    assert_equal false, @object.parked?
  end

  def test_should_not_output_warning
    assert_equal '', $stderr.string
  end

  def teardown
    $stderr = @original_stderr
  end
end

class StateWithConflictingMachineTest < MiniTest::Test
  def setup
    require 'stringio'
    @original_stderr, $stderr = $stderr, StringIO.new

    @klass = Class.new
    @state_machine = StateMachines::Machine.new(@klass, :state)
    @state_machine.states << @state = StateMachines::State.new(@state_machine, :parked)
  end

  def test_should_output_warning_if_using_different_attribute
    @status_machine = StateMachines::Machine.new(@klass, :status)
    @status_machine.states << @state = StateMachines::State.new(@status_machine, :parked)

    assert_equal "State :parked for :status is already defined in :state\n", $stderr.string
  end

  def test_should_not_output_warning_if_using_same_attribute
    @status_machine = StateMachines::Machine.new(@klass, :status, attribute: :state)
    @status_machine.states << @state = StateMachines::State.new(@status_machine, :parked)

    assert_equal '', $stderr.string
  end

  def test_should_not_output_warning_if_using_different_namespace
    @status_machine = StateMachines::Machine.new(@klass, :status, namespace: 'alarm')
    @status_machine.states << @state = StateMachines::State.new(@status_machine, :parked)

    assert_equal '', $stderr.string
  end

  def teardown
    $stderr = @original_stderr
  end
end

class StateWithConflictingMachineNameTest < MiniTest::Test
  def setup
    require 'stringio'
    @original_stderr, $stderr = $stderr, StringIO.new

    @klass = Class.new
    @state_machine = StateMachines::Machine.new(@klass, :state)
  end

  def test_should_output_warning_if_name_conflicts
    StateMachines::State.new(@state_machine, :state)
    assert_equal "Instance method \"state?\" is already defined in #{@klass} :state instance helpers, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string
  end

  def teardown
    $stderr = @original_stderr
  end
end

class StateWithNamespaceTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, namespace: 'alarm')
    @machine.states << @state = StateMachines::State.new(@machine, :active)
    @object = @klass.new
  end

  def test_should_have_a_name
    assert_equal :active, @state.name
  end

  def test_should_have_a_qualified_name
    assert_equal :alarm_active, @state.qualified_name
  end

  def test_should_namespace_predicate
    assert @object.respond_to?(:alarm_active?)
  end
end

class StateAfterBeingCopiedTest < MiniTest::Test
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @machine.states << @state = StateMachines::State.new(@machine, :parked)
    @copied_state = @state.dup
  end

  def test_should_not_have_the_context
    state_context = nil
    @state.context { state_context = self }

    copied_state_context = nil
    @copied_state.context { copied_state_context = self }

    refute_same state_context, copied_state_context
  end
end

class StateWithContextTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @ancestors = @klass.ancestors
    @machine.states << @state = StateMachines::State.new(@machine, :idling)

    context = nil
    speed_method = nil
    rpm_method = nil
    @result = @state.context do
      context = self

      def speed
        0
      end
      speed_method = instance_method(:speed)

      def rpm
        1000
      end
      rpm_method = instance_method(:rpm)
    end

    @context = context
    @speed_method = speed_method
    @rpm_method = rpm_method
  end

  def test_should_return_true
    assert_equal true, @result
  end

  def test_should_include_new_module_in_owner_class
    refute_equal @ancestors, @klass.ancestors
    assert_equal [@context], @klass.ancestors - @ancestors
  end

  def test_should_define_each_context_method_in_owner_class
    %w(speed rpm).each { |method| assert @klass.method_defined?(method) }
  end

  def test_should_define_aliased_context_method_in_owner_class
    %w(speed rpm).each { |method| assert @klass.method_defined?("__state_idling_#{method}_#{@context.object_id}__") }
  end

  def test_should_not_use_context_methods_as_owner_class_methods
    refute_equal @speed_method, @state.context_methods[:speed]
    refute_equal @rpm_method, @state.context_methods[:rpm]
  end

  def test_should_use_context_methods_as_aliased_owner_class_methods
    assert_equal @speed_method, @state.context_methods[:"__state_idling_speed_#{@context.object_id}__"]
    assert_equal @rpm_method, @state.context_methods[:"__state_idling_rpm_#{@context.object_id}__"]
  end
end

class StateWithMultipleContextsTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @ancestors = @klass.ancestors
    @machine.states << @state = StateMachines::State.new(@machine, :idling)

    context = nil
    speed_method = nil
    @state.context do
      context = self
      def speed
        0
      end

      speed_method = instance_method(:speed)
    end
    @context = context
    @speed_method = speed_method

    rpm_method = nil
    @state.context do
      def rpm
        1000
      end

      rpm_method = instance_method(:rpm)
    end
    @rpm_method = rpm_method
  end

  def test_should_include_new_module_in_owner_class
    refute_equal @ancestors, @klass.ancestors
    assert_equal [@context], @klass.ancestors - @ancestors
  end

  def test_should_define_each_context_method_in_owner_class
    %w(speed rpm).each { |method| assert @klass.method_defined?(method) }
  end

  def test_should_define_aliased_context_method_in_owner_class
    %w(speed rpm).each { |method| assert @klass.method_defined?("__state_idling_#{method}_#{@context.object_id}__") }
  end

  def test_should_not_use_context_methods_as_owner_class_methods
    refute_equal @speed_method, @state.context_methods[:speed]
    refute_equal @rpm_method, @state.context_methods[:rpm]
  end

  def test_should_use_context_methods_as_aliased_owner_class_methods
    assert_equal @speed_method, @state.context_methods[:"__state_idling_speed_#{@context.object_id}__"]
    assert_equal @rpm_method, @state.context_methods[:"__state_idling_rpm_#{@context.object_id}__"]
  end
end

class StateWithExistingContextMethodTest < MiniTest::Test
  def setup
    @klass = Class.new do
      def speed
        60
      end
    end
    @original_speed_method = @klass.instance_method(:speed)

    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, :idling)
    @state.context do
      def speed
        0
      end
    end
  end

  def test_should_not_override_method
    assert_equal @original_speed_method, @klass.instance_method(:speed)
  end
end

class StateWithRedefinedContextMethodTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.states << @state = StateMachines::State.new(@machine, 'on')

    old_context = nil
    old_speed_method = nil
    @state.context do
      old_context = self
      def speed
        0
      end
      old_speed_method = instance_method(:speed)
    end
    @old_context = old_context
    @old_speed_method = old_speed_method

    current_context = nil
    current_speed_method = nil
    @state.context do
      current_context = self
      def speed
        'green'
      end
      current_speed_method = instance_method(:speed)
    end
    @current_context = current_context
    @current_speed_method = current_speed_method
  end

  def test_should_track_latest_defined_method
    assert_equal @current_speed_method, @state.context_methods[:"__state_on_speed_#{@current_context.object_id}__"]
  end

  def test_should_have_the_same_context
    assert_equal @current_context, @old_context
  end
end

class StateWithInvalidMethodCallTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @ancestors = @klass.ancestors
    @machine.states << @state = StateMachines::State.new(@machine, :idling)
    @state.context do
      def speed
        0
      end
    end

    @object = @klass.new
  end

  def test_should_call_method_missing_arg
    assert_equal 1, @state.call(@object, :invalid, method_missing: lambda { 1 })
  end
end

class StateWithValidMethodCallForDifferentStateTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @ancestors = @klass.ancestors
    @machine.states << @state = StateMachines::State.new(@machine, :idling)
    @state.context do
      def speed
        0
      end
    end

    @object = @klass.new
  end

  def test_should_call_method_missing_arg
    assert_equal 1, @state.call(@object, :speed, method_missing: lambda { 1 })
  end

  def test_should_raise_invalid_context_on_no_method_error
    exception = assert_raises(StateMachines::InvalidContext) do
      @state.call(@object, :speed, method_missing: lambda { fail NoMethodError.new('Invalid', :speed, []) })
    end
    assert_equal @object, exception.object
    assert_equal 'State nil for :state is not a valid context for calling #speed', exception.message
  end

  def test_should_raise_original_error_on_no_method_error_with_different_arguments
    assert_raises(NoMethodError) do
      @state.call(@object, :speed, method_missing: lambda { fail NoMethodError.new('Invalid', :speed, [1]) })
    end
  end

  def test_should_raise_original_error_on_no_method_error_for_different_method
    assert_raises(NoMethodError) do
      @state.call(@object, :speed, method_missing: lambda { fail NoMethodError.new('Invalid', :rpm, []) })
    end
  end
end

class StateWithValidMethodCallForCurrentStateTest < MiniTest::Test
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :idling)
    @ancestors = @klass.ancestors
    @state = @machine.state(:idling)
    @state.context do
      def speed(arg = nil)
        block_given? ? [arg, yield] : arg
      end
    end

    @object = @klass.new
  end

  def test_should_not_raise_an_exception
    @state.call(@object, :speed, method_missing: lambda  { fail })
  end

  def test_should_pass_arguments_through
    assert_equal 1, @state.call(@object, :speed, 1, method_missing: lambda {})
  end

  def test_should_pass_blocks_through
    assert_equal [nil, 1], @state.call(@object, :speed) { 1 }
  end

  def test_should_pass_both_arguments_and_blocks_through
    assert_equal [1, 2], @state.call(@object, :speed, 1, method_missing: lambda {}) { 2 }
  end
end

if RUBY_VERSION > '1.8.7'
  class StateWithValidInheritedMethodCallForCurrentStateTest < MiniTest::Test
    def setup
      @superclass = Class.new do
        def speed(arg = nil)
          [arg]
        end
      end
      @klass = Class.new(@superclass)
      @machine = StateMachines::Machine.new(@klass, initial: :idling)
      @ancestors = @klass.ancestors
      @state = @machine.state(:idling)
      @state.context do
        def speed(arg = nil)
          [arg] + super(2)
        end
      end

      @object = @klass.new
    end

    def test_should_not_raise_an_exception
      @state.call(@object, :speed, method_missing: lambda  { fail })
    end

    def test_should_be_able_to_call_super
      assert_equal [1, 2], @state.call(@object, :speed, 1)
    end

    def test_should_allow_redefinition
      @state.context do
        def speed(arg = nil)
          [arg] + super(3)
        end
      end

      assert_equal [1, 3], @state.call(@object, :speed, 1)
    end
  end
end
