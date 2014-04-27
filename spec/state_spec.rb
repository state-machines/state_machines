require 'spec_helper'
describe StateMachines::State do
  context 'Drawing' do
    it 'should raise NotImplementedError' do
      machine = StateMachines::Machine.new(Class.new)
      state = StateMachines::State.new(machine, :parked)
      expect { state.draw(:foo) }.to raise_error(NotImplementedError)
    end
  end

  context 'ByDefault' do
    before(:each) do
      @machine = StateMachines::Machine.new(Class.new)
      @machine.states << @state = StateMachines::State.new(@machine, :parked)
    end

    it 'should_have_a_machine' do
      assert_equal @machine, @state.machine
    end

    it 'should_have_a_name' do
      assert_equal :parked, @state.name
    end

    it 'should_have_a_qualified_name' do
      assert_equal :parked, @state.qualified_name
    end

    it 'should_have_a_human_name' do
      assert_equal 'parked', @state.human_name
    end

    it 'should_use_stringify_the_name_as_the_value' do
      assert_equal 'parked', @state.value
    end

    it 'should_not_be_initial' do
      assert !@state.initial
    end

    it 'should_not_have_a_matcher' do
      assert_nil @state.matcher
    end

    it 'should_not_have_any_methods' do
      expected = {}
      assert_equal expected, @state.context_methods
    end
  end

  context '' do
    before(:each) do
      @machine = StateMachines::Machine.new(Class.new)
      @machine.states << @state = StateMachines::State.new(@machine, :parked)
    end

    it 'should_raise_exception_if_invalid_option_specified' do
      assert_raise(ArgumentError) { StateMachines::State.new(@machine, :parked, :invalid => true) }
      # FIXME
      # assert_equal 'Invalid key(s): invalid', exception.message
    end

    it 'should_allow_changing_machine' do
      new_machine = StateMachines::Machine.new(Class.new)
      @state.machine = new_machine
      assert_equal new_machine, @state.machine
    end

    it 'should_allow_changing_value' do
      @state.value = 1
      assert_equal 1, @state.value
    end

    it 'should_allow_changing_initial' do
      @state.initial = true
      assert @state.initial
    end

    it 'should_allow_changing_matcher' do
      matcher = lambda {}
      @state.matcher = matcher
      assert_equal matcher, @state.matcher
    end

    it 'should_allow_changing_human_name' do
      @state.human_name = 'stopped'
      assert_equal 'stopped', @state.human_name
    end

    it 'should_use_pretty_inspect' do
      assert_equal '#<StateMachines::State name=:parked value="parked" initial=false>', @state.inspect
    end
  end

  context 'WithoutName' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.states << @state = StateMachines::State.new(@machine, nil)
    end

    it 'should_have_a_nil_name' do
      assert_nil @state.name
    end

    it 'should_have_a_nil_qualified_name' do
      assert_nil @state.qualified_name
    end

    it 'should_have_an_empty_human_name' do
      assert_equal 'nil', @state.human_name
    end

    it 'should_have_a_nil_value' do
      assert_nil @state.value
    end

    it 'should_not_redefine_nil_predicate' do
      object = @klass.new
      assert !object.nil?
      assert !object.respond_to?('?')
    end

    it 'should_have_a_description' do
      assert_equal 'nil', @state.description
    end

    it 'should_have_a_description_using_human_name' do
      assert_equal 'nil', @state.description(:human_name => true)
    end
  end

  context 'WithName' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.states << @state = StateMachines::State.new(@machine, :parked)
    end

    it 'should_have_a_name' do
      assert_equal :parked, @state.name
    end

    it 'should_have_a_qualified_name' do
      assert_equal :parked, @state.name
    end

    it 'should_have_a_human_name' do
      assert_equal 'parked', @state.human_name
    end

    it 'should_use_stringify_the_name_as_the_value' do
      assert_equal 'parked', @state.value
    end

    it 'should_match_stringified_name' do
      assert @state.matches?('parked')
      assert !@state.matches?('idling')
    end

    it 'should_not_include_value_in_description' do
      assert_equal 'parked', @state.description
    end

    it 'should_allow_using_human_name_in_description' do
      @state.human_name = 'Parked'
      assert_equal 'Parked', @state.description(:human_name => true)
    end

    it 'should_define_predicate' do
      assert @klass.new.respond_to?(:parked?)
    end
  end

  context 'WithNilValue' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.states << @state = StateMachines::State.new(@machine, :parked, :value => nil)
    end

    it 'should_have_a_name' do
      assert_equal :parked, @state.name
    end

    it 'should_have_a_nil_value' do
      assert_nil @state.value
    end

    it 'should_match_nil_values' do
      assert @state.matches?(nil)
    end

    it 'should_have_a_description' do
      assert_equal 'parked (nil)', @state.description
    end

    it 'should_have_a_description_with_human_name' do
      @state.human_name = 'Parked'
      assert_equal 'Parked (nil)', @state.description(:human_name => true)
    end

    it 'should_define_predicate' do
      object = @klass.new
      assert object.respond_to?(:parked?)
    end
  end

  context 'WithSymbolicValue' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.states << @state = StateMachines::State.new(@machine, :parked, :value => :parked)
    end

    it 'should_use_custom_value' do
      assert_equal :parked, @state.value
    end

    it 'should_not_include_value_in_description' do
      assert_equal 'parked', @state.description
    end

    it 'should_allow_human_name_in_description' do
      @state.human_name = 'Parked'
      assert_equal 'Parked', @state.description(:human_name => true)
    end

    it 'should_match_symbolic_value' do
      assert @state.matches?(:parked)
      assert !@state.matches?('parked')
    end

    it 'should_define_predicate' do
      object = @klass.new
      assert object.respond_to?(:parked?)
    end
  end

  context 'WithIntegerValue' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.states << @state = StateMachines::State.new(@machine, :parked, :value => 1)
    end

    it 'should_use_custom_value' do
      assert_equal 1, @state.value
    end

    it 'should_include_value_in_description' do
      assert_equal 'parked (1)', @state.description
    end

    it 'should_allow_human_name_in_description' do
      @state.human_name = 'Parked'
      assert_equal 'Parked (1)', @state.description(:human_name => true)
    end

    it 'should_match_integer_value' do
      assert @state.matches?(1)
      assert !@state.matches?(2)
    end

    it 'should_define_predicate' do
      object = @klass.new
      assert object.respond_to?(:parked?)
    end
  end

  context 'WithLambdaValue' do
    before(:each) do
      @klass = Class.new
      @args = nil
      @machine = StateMachines::Machine.new(@klass)
      @value = lambda { |*args| @args = args; :parked }
      @machine.states << @state = StateMachines::State.new(@machine, :parked, :value => @value)
    end

    it 'should_use_evaluated_value_by_default' do
      assert_equal :parked, @state.value
    end

    it 'should_allow_access_to_original_value' do
      assert_equal @value, @state.value(false)
    end

    it 'should_include_masked_value_in_description' do
      assert_equal 'parked (*)', @state.description
    end

    it 'should_not_pass_in_any_arguments' do
      @state.value
      assert_equal [], @args
    end

    it 'should_define_predicate' do
      object = @klass.new
      assert object.respond_to?(:parked?)
    end

    it 'should_match_evaluated_value' do
      assert @state.matches?(:parked)
    end
  end

  context 'WithCachedLambdaValue' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @dynamic_value = lambda { 'value' }
      @machine.states << @state = StateMachines::State.new(@machine, :parked, :value => @dynamic_value, :cache => true)
    end

    it 'should_be_caching' do
      assert @state.cache
    end

    it 'should_evaluate_value' do
      assert_equal 'value', @state.value
    end

    it 'should_only_evaluate_value_once' do
      value = @state.value
      assert_same value, @state.value
    end

    it 'should_update_value_index_for_state_collection' do
      @state.value
      assert_equal @state, @machine.states['value', :value]
      assert_nil @machine.states[@dynamic_value, :value]
    end
  end

  context 'WithoutCachedLambdaValue' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @dynamic_value = lambda { 'value' }
      @machine.states << @state = StateMachines::State.new(@machine, :parked, :value => @dynamic_value)
    end

    it 'should_not_be_caching' do
      assert !@state.cache
    end

    it 'should_evaluate_value_each_time' do
      value = @state.value
      assert_not_same value, @state.value
    end

    it 'should_not_update_value_index_for_state_collection' do
      @state.value
      assert_nil @machine.states['value', :value]
      assert_equal @state, @machine.states[@dynamic_value, :value]
    end
  end

  context 'WithMatcher' do
    before(:each) do
      @klass = Class.new
      @args = nil
      @machine = StateMachines::Machine.new(@klass)
      @machine.states << @state = StateMachines::State.new(@machine, :parked, :if => lambda { |value| value == 1 })
    end

    it 'should_not_match_actual_value' do
      assert !@state.matches?('parked')
    end

    it 'should_match_evaluated_block' do
      assert @state.matches?(1)
    end
  end

  context 'WithHumanName' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.states << @state = StateMachines::State.new(@machine, :parked, :human_name => 'stopped')
    end

    it 'should_use_custom_human_name' do
      assert_equal 'stopped', @state.human_name
    end
  end

  context 'WithDynamicHumanName' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @machine.states << @state = StateMachines::State.new(@machine, :parked, :human_name => lambda { |state, object| ['stopped', object] })
    end

    it 'should_use_custom_human_name' do
      human_name, klass = @state.human_name
      assert_equal 'stopped', human_name
      assert_equal @klass, klass
    end

    it 'should_allow_custom_class_to_be_passed_through' do
      human_name, klass = @state.human_name(1)
      assert_equal 'stopped', human_name
      assert_equal 1, klass
    end

    it 'should_not_cache_value' do
      assert_not_same @state.human_name, @state.human_name
    end
  end

  context 'Initial' do
    before(:each) do
      @machine = StateMachines::Machine.new(Class.new)
      @machine.states << @state = StateMachines::State.new(@machine, :parked, :initial => true)
    end

    it 'should_be_initial' do
      assert @state.initial
      assert @state.initial?
    end
  end

  context 'NotInitial' do
    before(:each) do
      @machine = StateMachines::Machine.new(Class.new)
      @machine.states << @state = StateMachines::State.new(@machine, :parked, :initial => false)
    end

    it 'should_not_be_initial' do
      assert !@state.initial
      assert !@state.initial?
    end
  end

  context 'Final' do
    before(:each) do
      @machine = StateMachines::Machine.new(Class.new)
      @machine.states << @state = StateMachines::State.new(@machine, :parked)
    end

    it 'should_be_final_without_input_transitions' do
      assert @state.final?
    end

    it 'should_be_final_with_input_transitions' do
      @machine.event :park do
        transition :idling => :parked
      end

      assert @state.final?
    end

    it 'should_be_final_with_loopback' do
      @machine.event :ignite do
        transition :parked => same
      end

      assert @state.final?
    end
  end

  context 'NotFinal' do
    before(:each) do
      @machine = StateMachines::Machine.new(Class.new)
      @machine.states << @state = StateMachines::State.new(@machine, :parked)
    end

    it 'should_not_be_final_with_outgoing_whitelist_transitions' do
      @machine.event :ignite do
        transition :parked => :idling
      end

      assert !@state.final?
    end

    it 'should_not_be_final_with_outgoing_all_transitions' do
      @machine.event :ignite do
        transition all => :idling
      end

      assert !@state.final?
    end

    it 'should_not_be_final_with_outgoing_blacklist_transitions' do
      @machine.event :ignite do
        transition all - :first_gear => :idling
      end

      assert !@state.final?
    end
  end

  context 'WithConflictingHelpersBeforeDefinition' do
    before(:each) do
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

    it 'should_not_override_state_predicate' do
      assert_equal 0, @object.parked?
    end

    it 'should_output_warning' do
      assert_equal "Instance method \"parked?\" is already defined in #{@superclass.to_s}, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string
    end

    def teardown
      $stderr = @original_stderr
    end
  end

  context 'WithConflictingHelpersAfterDefinition' do
    before(:each) do
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

    it 'should_not_override_state_predicate' do
      assert_equal 0, @object.parked?
    end

    it 'should_still_allow_super_chaining' do
      @klass.class_eval do
        def parked?
          super
        end
      end

      assert_equal false, @object.parked?
    end

    it 'should_not_output_warning' do
      assert_equal '', $stderr.string
    end

    def teardown
      $stderr = @original_stderr
    end
  end

  context 'WithConflictingMachine' do
    before(:each) do
      require 'stringio'
      @original_stderr, $stderr = $stderr, StringIO.new

      @klass = Class.new
      @state_machine = StateMachines::Machine.new(@klass, :state)
      @state_machine.states << @state = StateMachines::State.new(@state_machine, :parked)
    end

    it 'should_output_warning_if_using_different_attribute' do
      @status_machine = StateMachines::Machine.new(@klass, :status)
      @status_machine.states << @state = StateMachines::State.new(@status_machine, :parked)

      assert_equal "State :parked for :status is already defined in :state\n", $stderr.string
    end

    it 'should_not_output_warning_if_using_same_attribute' do
      @status_machine = StateMachines::Machine.new(@klass, :status, :attribute => :state)
      @status_machine.states << @state = StateMachines::State.new(@status_machine, :parked)

      assert_equal '', $stderr.string
    end

    it 'should_not_output_warning_if_using_different_namespace' do
      @status_machine = StateMachines::Machine.new(@klass, :status, :namespace => 'alarm')
      @status_machine.states << @state = StateMachines::State.new(@status_machine, :parked)

      assert_equal '', $stderr.string
    end

    def teardown
      $stderr = @original_stderr
    end
  end

  context 'WithConflictingMachineName' do
    before(:each) do
      require 'stringio'
      @original_stderr, $stderr = $stderr, StringIO.new

      @klass = Class.new
      @state_machine = StateMachines::Machine.new(@klass, :state)
    end

    it 'should_output_warning_if_name_conflicts' do
      StateMachines::State.new(@state_machine, :state)
      assert_equal "Instance method \"state?\" is already defined in #{@klass} :state instance helpers, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string
    end

    def teardown
      $stderr = @original_stderr
    end
  end

  context 'WithNamespace' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass, :namespace => 'alarm')
      @machine.states << @state = StateMachines::State.new(@machine, :active)
      @object = @klass.new
    end

    it 'should_have_a_name' do
      assert_equal :active, @state.name
    end

    it 'should_have_a_qualified_name' do
      assert_equal :alarm_active, @state.qualified_name
    end

    it 'should_namespace_predicate' do
      assert @object.respond_to?(:alarm_active?)
    end
  end

  context 'AfterBeingCopied' do
    before(:each) do
      @machine = StateMachines::Machine.new(Class.new)
      @machine.states << @state = StateMachines::State.new(@machine, :parked)
      @copied_state = @state.dup
    end

    it 'should_not_have_the_context' do
      state_context = nil
      @state.context { state_context = self }

      copied_state_context = nil
      @copied_state.context { copied_state_context = self }

      assert_not_same state_context, copied_state_context
    end
  end

  context 'WithContext' do
    before(:each) do
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

    it 'should_return_true' do
      assert_equal true, @result
    end

    it 'should_include_new_module_in_owner_class' do
      assert_not_equal @ancestors, @klass.ancestors
      assert_equal [@context], @klass.ancestors - @ancestors
    end

    it 'should_define_each_context_method_in_owner_class' do
      %w(speed rpm).each { |method| assert @klass.method_defined?(method) }
    end

    it 'should_define_aliased_context_method_in_owner_class' do
      %w(speed rpm).each { |method| assert @klass.method_defined?("__state_idling_#{method}_#{@context.object_id}__") }
    end

    it 'should_not_use_context_methods_as_owner_class_methods' do
      assert_not_equal @speed_method, @state.context_methods[:speed]
      assert_not_equal @rpm_method, @state.context_methods[:rpm]
    end

    it 'should_use_context_methods_as_aliased_owner_class_methods' do
      assert_equal @speed_method, @state.context_methods[:"__state_idling_speed_#{@context.object_id}__"]
      assert_equal @rpm_method, @state.context_methods[:"__state_idling_rpm_#{@context.object_id}__"]
    end
  end

  context 'WithMultipleContexts' do
    before(:each) do
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

    it 'should_include_new_module_in_owner_class' do
      assert_not_equal @ancestors, @klass.ancestors
      assert_equal [@context], @klass.ancestors - @ancestors
    end

    it 'should_define_each_context_method_in_owner_class' do
      %w(speed rpm).each { |method| assert @klass.method_defined?(method) }
    end

    it 'should_define_aliased_context_method_in_owner_class' do
      %w(speed rpm).each { |method| assert @klass.method_defined?("__state_idling_#{method}_#{@context.object_id}__") }
    end

    it 'should_not_use_context_methods_as_owner_class_methods' do
      assert_not_equal @speed_method, @state.context_methods[:speed]
      assert_not_equal @rpm_method, @state.context_methods[:rpm]
    end

    it 'should_use_context_methods_as_aliased_owner_class_methods' do
      assert_equal @speed_method, @state.context_methods[:"__state_idling_speed_#{@context.object_id}__"]
      assert_equal @rpm_method, @state.context_methods[:"__state_idling_rpm_#{@context.object_id}__"]
    end
  end

  context 'WithExistingContextMethod' do
    before(:each) do
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

    it 'should_not_override_method' do
      assert_equal @original_speed_method, @klass.instance_method(:speed)
    end
  end

  context 'WithRedefinedContextMethod' do
    before(:each) do
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

    it 'should_track_latest_defined_method' do
      assert_equal @current_speed_method, @state.context_methods[:"__state_on_speed_#{@current_context.object_id}__"]
    end

    it 'should_have_the_same_context' do
      assert_equal @current_context, @old_context
    end
  end

  context 'WithInvalidMethodCall' do
    before(:each) do
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

    it 'should_call_method_missing_arg' do
      assert_equal 1, @state.call(@object, :invalid, :method_missing => lambda { 1 })
    end
  end

  context 'WithValidMethodCallForDifferentState' do
    before(:each) do
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

    it 'should_call_method_missing_arg' do
      assert_equal 1, @state.call(@object, :speed, :method_missing => lambda { 1 })
    end

    it 'should_raise_invalid_context_on_no_method_error' do
      assert_raise(StateMachines::InvalidContext) do
        @state.call(@object, :speed, :method_missing => lambda { raise NoMethodError.new('Invalid', :speed, []) })
      end
      # FIXME
      # assert_equal @object, exception.object
      # assert_equal 'State nil for :state is not a valid context for calling #speed', exception.message
    end

    it 'should_raise_original_error_on_no_method_error_with_different_arguments' do
      assert_raise(NoMethodError) do
        @state.call(@object, :speed, :method_missing => lambda { raise NoMethodError.new('Invalid', :speed, [1]) })
      end
    end

    it 'should_raise_original_error_on_no_method_error_for_different_method' do
      assert_raise(NoMethodError) do
        @state.call(@object, :speed, :method_missing => lambda { raise NoMethodError.new('Invalid', :rpm, []) })
      end
    end
  end

  context 'WithValidMethodCallForCurrentState' do
    before(:each) do
      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass, :initial => :idling)
      @ancestors = @klass.ancestors
      @state = @machine.state(:idling)
      @state.context do
        def speed(arg = nil)
          block_given? ? [arg, yield] : arg
        end
      end

      @object = @klass.new
    end

    it 'should_not_raise_an_exception' do
      assert_nothing_raised { @state.call(@object, :speed, :method_missing => lambda { raise }) }
    end

    it 'should_pass_arguments_through' do
      assert_equal 1, @state.call(@object, :speed, 1, :method_missing => lambda {})
    end

    it 'should_pass_blocks_through' do
      assert_equal [nil, 1], @state.call(@object, :speed) { 1 }
    end

    it 'should_pass_both_arguments_and_blocks_through' do
      assert_equal [1, 2], @state.call(@object, :speed, 1, :method_missing => lambda {}) { 2 }
    end
  end

  if RUBY_VERSION > '1.8.7'
    context 'WithValidInheritedMethodCallForCurrentState' do
      before(:each) do
        @superclass = Class.new do
          def speed(arg = nil)
            [arg]
          end
        end
        @klass = Class.new(@superclass)
        @machine = StateMachines::Machine.new(@klass, :initial => :idling)
        @ancestors = @klass.ancestors
        @state = @machine.state(:idling)
        @state.context do
          def speed(arg = nil)
            [arg] + super(2)
          end
        end

        @object = @klass.new
      end

      it 'should_not_raise_an_exception' do
        assert_nothing_raised { @state.call(@object, :speed, :method_missing => lambda { raise }) }
      end

      it 'should_be_able_to_call_super' do
        assert_equal [1, 2], @state.call(@object, :speed, 1)
      end

      it 'should_allow_redefinition' do
        @state.context do
          def speed(arg = nil)
            [arg] + super(3)
          end
        end

        assert_equal [1, 3], @state.call(@object, :speed, 1)
      end
    end
  end
end
