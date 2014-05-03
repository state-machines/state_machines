require 'spec_helper'

describe StateMachines::Callback do

  context 'Default' do
    it 'should_raise_exception_if_invalid_type_specified' do
      assert_raise(ArgumentError) { StateMachines::Callback.new(:invalid) {} }
    end

    it 'should_not_raise_exception_if_using_before_type' do
      assert_nothing_raised { StateMachines::Callback.new(:before) {} }
    end

    it 'should_not_raise_exception_if_using_after_type' do
      assert_nothing_raised { StateMachines::Callback.new(:after) {} }
    end

    it 'should_not_raise_exception_if_using_around_type' do
      assert_nothing_raised { StateMachines::Callback.new(:around) {} }
    end

    it 'should_not_raise_exception_if_using_failure_type' do
      assert_nothing_raised { StateMachines::Callback.new(:failure) {} }
    end

    it 'should_raise_exception_if_no_methods_specified' do
      assert_raise(ArgumentError) { StateMachines::Callback.new(:before) }
    end

    it 'should_not_raise_exception_if_method_specified_in_do_option' do
      assert_nothing_raised { StateMachines::Callback.new(:before, :do => :run) }
    end

    it 'should_not_raise_exception_if_method_specified_as_argument' do
      assert_nothing_raised { StateMachines::Callback.new(:before, :run) }
    end

    it 'should_not_raise_exception_if_method_specified_as_block' do
      assert_nothing_raised { StateMachines::Callback.new(:before, :run) {} }
    end

    it 'should_not_raise_exception_if_implicit_option_specified' do
      assert_nothing_raised { StateMachines::Callback.new(:before, :do => :run, :invalid => :valid) }
    end

    it 'should_not_bind_to_objects' do
      assert !StateMachines::Callback.bind_to_object
    end

    it 'should_not_have_a_terminator' do
      assert_nil StateMachines::Callback.terminator
    end
  end

  context 'ByDefault' do
    before(:each) do
      @callback = StateMachines::Callback.new(:before) {}
    end

    it 'should_have_type' do
      assert_equal :before, @callback.type
    end

    it 'should_not_have_a_terminator' do
      assert_nil @callback.terminator
    end

    it 'should_have_a_branch_with_all_matcher_requirements' do
      assert_equal StateMachines::AllMatcher.instance, @callback.branch.event_requirement
      assert_equal StateMachines::AllMatcher.instance, @callback.branch.state_requirements.first[:from]
      assert_equal StateMachines::AllMatcher.instance, @callback.branch.state_requirements.first[:to]
    end

    it 'should_not_have_any_known_states' do
      assert_equal [], @callback.known_states
    end
  end

  context 'WithMethodArgument' do
    before(:each) do
      @callback = StateMachines::Callback.new(:before, lambda {|*args| @args = args})

      @object = Object.new
      @result = @callback.call(@object)
    end

    it 'should_be_successful' do
      assert @result
    end

    it 'should_call_with_empty_context' do
      assert_equal [@object], @args
    end
  end

  context 'WithMultipleMethodArguments' do
    before(:each) do
      @callback = StateMachines::Callback.new(:before, :run_1, :run_2)

      class << @object = Object.new
        attr_accessor :callbacks

        def run_1
          (@callbacks ||= []) << :run_1
        end

        def run_2
          (@callbacks ||= []) << :run_2
        end
      end

      @result = @callback.call(@object)
    end

    it 'should_be_successful' do
      assert @result
    end

    it 'should_call_each_callback_in_order' do
      assert_equal [:run_1, :run_2], @object.callbacks
    end
  end

  context 'WithDoMethod' do
    before(:each) do
      @callback = StateMachines::Callback.new(:before, :do => lambda {|*args| @args = args})

      @object = Object.new
      @result = @callback.call(@object)
    end

    it 'should_be_successful' do
      assert @result
    end

    it 'should_call_with_empty_context' do
      assert_equal [@object], @args
    end
  end

  context 'WithMultipleDoMethods' do
    before(:each) do
      @callback = StateMachines::Callback.new(:before, :do => [:run_1, :run_2])

      class << @object = Object.new
        attr_accessor :callbacks

        def run_1
          (@callbacks ||= []) << :run_1
        end

        def run_2
          (@callbacks ||= []) << :run_2
        end
      end

      @result = @callback.call(@object)
    end

    it 'should_be_successful' do
      assert @result
    end

    it 'should_call_each_callback_in_order' do
      assert_equal [:run_1, :run_2], @object.callbacks
    end
  end

  context 'WithBlock' do
    before(:each) do
      @callback = StateMachines::Callback.new(:before) do |*args|
        @args = args
      end

      @object = Object.new
      @result = @callback.call(@object)
    end

    it 'should_be_successful' do
      assert @result
    end

    it 'should_call_with_empty_context' do
      assert_equal [@object], @args
    end
  end

  context 'WithMixedMethods' do
    before(:each) do
      @callback = StateMachines::Callback.new(:before, :run_argument, :do => :run_do) do |object|
        object.callbacks << :block
      end

      class << @object = Object.new
        attr_accessor :callbacks

        def run_argument
          (@callbacks ||= []) << :argument
        end

        def run_do
          (@callbacks ||= []) << :do
        end
      end

      @result = @callback.call(@object)
    end

    it 'should_be_successful' do
      assert @result
    end

    it 'should_call_each_callback_in_order' do
      assert_equal [:argument, :do, :block], @object.callbacks
    end
  end

  context 'WithExplicitRequirements' do
    before(:each) do
      @object = Object.new
      @callback = StateMachines::Callback.new(:before, :from => :parked, :to => :idling, :on => :ignite, :do => lambda {})
    end

    it 'should_call_with_empty_context' do
      assert @callback.call(@object, {})
    end

    it 'should_not_call_if_from_not_included' do
      assert !@callback.call(@object, :from => :idling)
    end

    it 'should_not_call_if_to_not_included' do
      assert !@callback.call(@object, :to => :parked)
    end

    it 'should_not_call_if_on_not_included' do
      assert !@callback.call(@object, :on => :park)
    end

    it 'should_call_if_all_requirements_met' do
      assert @callback.call(@object, :from => :parked, :to => :idling, :on => :ignite)
    end

    it 'should_include_in_known_states' do
      assert_equal [:parked, :idling], @callback.known_states
    end
  end

  context 'WithImplicitRequirements' do
    before(:each) do
      @object = Object.new
      @callback = StateMachines::Callback.new(:before, :parked => :idling, :on => :ignite, :do => lambda {})
    end

    it 'should_call_with_empty_context' do
      assert @callback.call(@object, {})
    end

    it 'should_not_call_if_from_not_included' do
      assert !@callback.call(@object, :from => :idling)
    end

    it 'should_not_call_if_to_not_included' do
      assert !@callback.call(@object, :to => :parked)
    end

    it 'should_not_call_if_on_not_included' do
      assert !@callback.call(@object, :on => :park)
    end

    it 'should_call_if_all_requirements_met' do
      assert @callback.call(@object, :from => :parked, :to => :idling, :on => :ignite)
    end

    it 'should_include_in_known_states' do
      assert_equal [:parked, :idling], @callback.known_states
    end
  end

  context 'WithIfCondition' do
    before(:each) do
      @object = Object.new
    end

    it 'should_call_if_true' do
      callback = StateMachines::Callback.new(:before, :if => lambda {true}, :do => lambda {})
      assert callback.call(@object)
    end

    it 'should_not_call_if_false' do
      callback = StateMachines::Callback.new(:before, :if => lambda {false}, :do => lambda {})
      assert !callback.call(@object)
    end
  end

  context 'WithUnlessCondition' do
    before(:each) do
      @object = Object.new
    end

    it 'should_call_if_false' do
      callback = StateMachines::Callback.new(:before, :unless => lambda {false}, :do => lambda {})
      assert callback.call(@object)
    end

    it 'should_not_call_if_true' do
      callback = StateMachines::Callback.new(:before, :unless => lambda {true}, :do => lambda {})
      assert !callback.call(@object)
    end
  end

  context 'WithoutTerminator' do
    before(:each) do
      @object = Object.new
    end

    it 'should_not_halt_if_result_is_false' do
      callback = StateMachines::Callback.new(:before, :do => lambda {false}, :terminator => nil)
      assert_nothing_thrown { callback.call(@object) }
    end
  end

  context 'WithTerminator' do
    before(:each) do
      @object = Object.new
    end

    it 'should_not_halt_if_terminator_does_not_match' do
      callback = StateMachines::Callback.new(:before, :do => lambda {false}, :terminator => lambda {|result| result == true})
      assert_nothing_thrown { callback.call(@object) }
    end

    it 'should_halt_if_terminator_matches' do
      callback = StateMachines::Callback.new(:before, :do => lambda {false}, :terminator => lambda {|result| result == false})
      assert_throws(:halt) { callback.call(@object) }
    end

    it 'should_halt_if_terminator_matches_any_method' do
      callback = StateMachines::Callback.new(:before, :do => [lambda {true}, lambda {false}], :terminator => lambda {|result| result == false})
      assert_throws(:halt) { callback.call(@object) }
    end
  end

  context 'WithoutArguments' do
    before(:each) do
      @callback = StateMachines::Callback.new(:before, :do => lambda {|object| @arg = object})

      @object = Object.new
      @callback.call(@object, {}, 1, 2, 3)
    end

    it 'should_call_method_with_object_as_argument' do
      assert_equal @object, @arg
    end
  end

  context 'WithArguments' do
    before(:each) do
      @callback = StateMachines::Callback.new(:before, :do => lambda {|*args| @args = args})

      @object = Object.new
      @callback.call(@object, {}, 1, 2, 3)
    end

    it 'should_call_method_with_all_arguments' do
      assert_equal [@object, 1, 2, 3], @args
    end
  end

  context 'WithUnboundMethod' do
    before(:each) do
      @callback = StateMachines::Callback.new(:before, :do => lambda {|*args| @context = args.unshift(self)})

      @object = Object.new
      @callback.call(@object, {}, 1, 2, 3)
    end

    it 'should_call_method_outside_the_context_of_the_object' do
      assert_equal [self, @object, 1, 2, 3], @context
    end
  end

  context 'WithBoundMethod' do
    before(:each) do
      @object = Object.new
    end

    it 'should_call_method_within_the_context_of_the_object_for_block_methods' do
      context = nil
      callback = StateMachines::Callback.new(:before, :do => lambda {|*args| context = [self] + args}, :bind_to_object => true)
      callback.call(@object, {}, 1, 2, 3)

      assert_equal [@object, 1, 2, 3], context
    end

    it 'should_ignore_option_for_symbolic_methods' do
      class << @object
        attr_reader :context

        def after_ignite(*args)
          @context = args
        end
      end

      callback = StateMachines::Callback.new(:before, :do => :after_ignite, :bind_to_object => true)
      callback.call(@object)

      assert_equal [], @object.context
    end

    it 'should_ignore_option_for_string_methods' do
      callback = StateMachines::Callback.new(:before, :do => '[1, 2, 3]', :bind_to_object => true)
      assert callback.call(@object)
    end
  end

  context 'WithMultipleBoundMethods' do
    before(:each) do
      @object = Object.new

      first_context = nil
      second_context = nil

      @callback = StateMachines::Callback.new(:before, :do => [lambda {first_context = self}, lambda {second_context = self}], :bind_to_object => true)
      @callback.call(@object)

      @first_context = first_context
      @second_context = second_context
    end

    it 'should_call_each_method_within_the_context_of_the_object' do
      assert_equal @object, @first_context
      assert_equal @object, @second_context
    end
  end

  context 'WithApplicationBoundObject' do
    before(:each) do
      @original_bind_to_object = StateMachines::Callback.bind_to_object
      StateMachines::Callback.bind_to_object = true

      context = nil
      @callback = StateMachines::Callback.new(:before, :do => lambda {|*args| context = self})

      @object = Object.new
      @callback.call(@object)
      @context = context
    end

    it 'should_call_method_within_the_context_of_the_object' do
      assert_equal @object, @context
    end

    after(:each) do
      StateMachines::Callback.bind_to_object = @original_bind_to_object
    end
  end

  context 'WithBoundMethodAndArguments' do
    before(:each) do
      @object = Object.new
    end

    it 'should_include_single_argument_if_specified' do
      context = nil
      callback = StateMachines::Callback.new(:before, :do => lambda {|arg1| context = [arg1]}, :bind_to_object => true)
      callback.call(@object, {}, 1)
      assert_equal [1], context
    end

    it 'should_include_multiple_arguments_if_specified' do
      context = nil
      callback = StateMachines::Callback.new(:before, :do => lambda {|arg1, arg2, arg3| context = [arg1, arg2, arg3]}, :bind_to_object => true)
      callback.call(@object, {}, 1, 2, 3)
      assert_equal [1, 2, 3], context
    end

    it 'should_include_arguments_if_splat_used' do
      context = nil
      callback = StateMachines::Callback.new(:before, :do => lambda {|*args| context = args}, :bind_to_object => true)
      callback.call(@object, {}, 1, 2, 3)
      assert_equal [1, 2, 3], context
    end
  end

  context 'WithApplicationTerminator' do
    before(:each) do
      @original_terminator = StateMachines::Callback.terminator
      StateMachines::Callback.terminator = lambda {|result| result == false}

      @object = Object.new
    end

    it 'should_not_halt_if_terminator_does_not_match' do
      callback = StateMachines::Callback.new(:before, :do => lambda {true})
      assert_nothing_thrown { callback.call(@object) }
    end

    it 'should_halt_if_terminator_matches' do
      callback = StateMachines::Callback.new(:before, :do => lambda {false})
      assert_throws(:halt) { callback.call(@object) }
    end

    def teardown
      StateMachines::Callback.terminator = @original_terminator
    end
  end

  context 'WithAroundTypeAndBlock' do
    before(:each) do
      @object = Object.new
      @callbacks = []
    end

    it 'should_evaluate_before_without_after' do
      callback = StateMachines::Callback.new(:around, lambda {|*args| block = args.pop; @args = args; block.call})
      assert callback.call(@object)
      assert_equal [@object], @args
    end

    it 'should_evaluate_after_without_before' do
      callback = StateMachines::Callback.new(:around, lambda {|*args| block = args.pop; block.call; @args = args})
      assert callback.call(@object)
      assert_equal [@object], @args
    end

    it 'should_halt_if_not_yielded' do
      callback = StateMachines::Callback.new(:around, lambda {|block|})
      assert_throws(:halt) { callback.call(@object) }
    end

    it 'should_call_block_after_before' do
      callback = StateMachines::Callback.new(:around, lambda {|block| @callbacks << :before; block.call})
      assert callback.call(@object) { @callbacks << :block }
      assert_equal [:before, :block], @callbacks
    end

    it 'should_call_block_before_after' do
      @callbacks = []
      callback = StateMachines::Callback.new(:around, lambda {|block| block.call; @callbacks << :after})
      assert callback.call(@object) { @callbacks << :block }
      assert_equal [:block, :after], @callbacks
    end

    it 'should_halt_if_block_halts' do
      callback = StateMachines::Callback.new(:around, lambda {|block| block.call; @callbacks << :after})
      assert_throws(:halt) { callback.call(@object) { throw :halt }  }
      assert_equal [], @callbacks
    end
  end

  context 'WithAroundTypeAndMultipleMethods' do
    before(:each) do
      @callback = StateMachines::Callback.new(:around, :run_1, :run_2)

      class << @object = Object.new
        attr_accessor :before_callbacks
        attr_accessor :after_callbacks

        def run_1
          (@before_callbacks ||= []) << :run_1
          yield
          (@after_callbacks ||= []) << :run_1
        end

        def run_2
          (@before_callbacks ||= []) << :run_2
          yield
          (@after_callbacks ||= []) << :run_2
        end
      end
    end

    it 'should_succeed' do
      assert @callback.call(@object)
    end

    it 'should_evaluate_before_callbacks_in_order' do
      @callback.call(@object)
      assert_equal [:run_1, :run_2], @object.before_callbacks
    end

    it 'should_evaluate_after_callbacks_in_reverse_order' do
      @callback.call(@object)
      assert_equal [:run_2, :run_1], @object.after_callbacks
    end

    it 'should_call_block_after_before_callbacks' do
      @callback.call(@object) { (@object.before_callbacks ||= []) << :block }
      assert_equal [:run_1, :run_2, :block], @object.before_callbacks
    end

    it 'should_call_block_before_after_callbacks' do
      @callback.call(@object) { (@object.after_callbacks ||= []) << :block }
      assert_equal [:block, :run_2, :run_1], @object.after_callbacks
    end

    it 'should_halt_if_first_doesnt_yield' do
      class << @object
        remove_method :run_1
        def run_1
          (@before_callbacks ||= []) << :run_1
        end
      end

      catch(:halt) do
        @callback.call(@object) { (@object.before_callbacks ||= []) << :block }
      end

      assert_equal [:run_1], @object.before_callbacks
      assert_nil @object.after_callbacks
    end

    it 'should_halt_if_last_doesnt_yield' do
      class << @object
        remove_method :run_2
        def run_2
          (@before_callbacks ||= []) << :run_2
        end
      end

      catch(:halt) { @callback.call(@object) }
      assert_equal [:run_1, :run_2], @object.before_callbacks
      assert_nil @object.after_callbacks
    end

    it 'should_not_evaluate_further_methods_if_after_halts' do
      class << @object
        remove_method :run_2
        def run_2
          (@before_callbacks ||= []) << :run_2
          yield
          (@after_callbacks ||= []) << :run_2
          throw :halt
        end
      end

      catch(:halt) { @callback.call(@object) }
      assert_equal [:run_1, :run_2], @object.before_callbacks
      assert_equal [:run_2], @object.after_callbacks
    end
  end

  context 'WithAroundTypeAndArguments' do
    before(:each) do
      @object = Object.new
    end

    it 'should_include_object_if_specified' do
      callback = StateMachines::Callback.new(:around, lambda {|object, block| @args = [object]; block.call})
      callback.call(@object)
      assert_equal [@object], @args
    end

    it 'should_include_arguments_if_specified' do
      callback = StateMachines::Callback.new(:around, lambda {|object, arg1, arg2, arg3, block| @args = [object, arg1, arg2, arg3]; block.call})
      callback.call(@object, {}, 1, 2, 3)
      assert_equal [@object, 1, 2, 3], @args
    end

    it 'should_include_arguments_if_splat_used' do
      callback = StateMachines::Callback.new(:around, lambda {|*args| block = args.pop; @args = args; block.call})
      callback.call(@object, {}, 1, 2, 3)
      assert_equal [@object, 1, 2, 3], @args
    end
  end

  context 'WithAroundTypeAndTerminator' do
    before(:each) do
      @object = Object.new
    end

    it 'should_not_halt_if_terminator_does_not_match' do
      callback = StateMachines::Callback.new(:around, :do => lambda {|block| block.call(false); false}, :terminator => lambda {|result| result == true})
      assert_nothing_thrown { callback.call(@object) }
    end

    it 'should_not_halt_if_terminator_matches' do
      callback = StateMachines::Callback.new(:around, :do => lambda {|block| block.call(false); false}, :terminator => lambda {|result| result == false})
      assert_nothing_thrown { callback.call(@object) }
    end
  end

  context 'WithAroundTypeAndBoundMethod' do
    before(:each) do
      @object = Object.new
    end

    it 'should_call_method_within_the_context_of_the_object' do
      context = nil
      callback = StateMachines::Callback.new(:around, :do => lambda {|block| context = self; block.call}, :bind_to_object => true)
      callback.call(@object, {}, 1, 2, 3)

      assert_equal @object, context
    end

    it 'should_include_arguments_if_specified' do
      context = nil
      callback = StateMachines::Callback.new(:around, :do => lambda {|*args| block = args.pop; context = args; block.call}, :bind_to_object => true)
      callback.call(@object, {}, 1, 2, 3)

      assert_equal [1, 2, 3], context
    end
  end

end