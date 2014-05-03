describe StateMachines::Machine do
  let(:klass) { Class.new }
  let(:machine) { StateMachines::Machine.new(klass) }

  let(:object) { klass.new }

  describe 'machine' do
    before(:each) do
      machine
    end
    it 'should_have_an_owner_class' do
      assert_equal klass, machine.owner_class
    end

    it 'should_have_a_name' do
      assert_equal :state, machine.name
    end

    it 'should_have_an_attribute' do
      assert_equal :state, machine.attribute
    end

    it 'should_prefix_custom_attributes_with_attribute' do
      assert_equal :state_event, machine.attribute(:event)
    end

    it 'should_have_an_initial_state' do
      assert_not_nil machine.initial_state(object)
    end

    it 'should_have_a_nil_initial_state' do
      assert_nil machine.initial_state(object).value
    end

    it 'should_not_have_any_events' do
      assert !machine.events.any?
    end

    it 'should_not_have_any_before_callbacks' do
      assert machine.callbacks[:before].empty?
    end

    it 'should_not_have_any_after_callbacks' do
      assert machine.callbacks[:after].empty?
    end

    it 'should_not_have_any_failure_callbacks' do
      assert machine.callbacks[:failure].empty?
    end

    it 'should_not_have_an_action' do
      assert_nil machine.action
    end

    it 'should_use_tranactions' do
      assert_equal true, machine.use_transactions
    end

    it 'should_not_have_a_namespace' do
      assert_nil machine.namespace
    end

    it 'should_have_a_nil_state' do
      assert_equal [nil], machine.states.keys
    end

    it 'should_set_initial_on_nil_state' do
      assert machine.state(nil).initial
    end

    it 'should_generate_default_messages' do
      assert_equal 'is invalid', machine.generate_message(:invalid)
      assert_equal 'cannot transition when parked', machine.generate_message(:invalid_event, [[:state, :parked]])
      assert_equal 'cannot transition via "park"', machine.generate_message(:invalid_transition, [[:event, :park]])
    end

    it 'should_not_be_extended_by_the_base_integration' do
      assert !(
      class << machine
        ancestors
      end).include?(StateMachines::Integrations::Base)
    end


    it 'should_define_a_reader_attribute_for_the_attribute' do
      assert object.respond_to?(:state)
    end

    it 'should_define_a_writer_attribute_for_the_attribute' do
      assert object.respond_to?(:state=)
    end

    it 'should_define_a_predicate_for_the_attribute' do
      assert object.respond_to?(:state?)
    end

    it 'should_define_a_name_reader_for_the_attribute' do
      assert object.respond_to?(:state_name)
    end

    it 'should_define_an_event_reader_for_the_attribute' do
      assert object.respond_to?(:state_events)
    end

    it 'should_define_a_transition_reader_for_the_attribute' do
      assert object.respond_to?(:state_transitions)
    end

    it 'should_define_a_path_reader_for_the_attribute' do
      assert object.respond_to?(:state_paths)
    end

    it 'should_define_an_event_runner_for_the_attribute' do
      assert object.respond_to?(:fire_state_event)
    end

    it 'should_not_define_an_event_attribute_reader' do
      assert !object.respond_to?(:state_event)
    end

    it 'should_not_define_an_event_attribute_writer' do
      assert !object.respond_to?(:state_event=)
    end

    it 'should_not_define_an_event_transition_attribute_reader' do
      assert !object.respond_to?(:state_event_transition)
    end

    it 'should_not_define_an_event_transition_attribute_writer' do
      assert !object.respond_to?(:state_event_transition=)
    end

    it 'should_define_a_human_attribute_name_reader_for_the_attribute' do
      assert klass.respond_to?(:human_state_name)
    end

    it 'should_define_a_human_event_name_reader_for_the_attribute' do
      assert klass.respond_to?(:human_state_event_name)
    end

    it 'should_not_define_singular_with_scope' do
      assert !klass.respond_to?(:with_state)
    end

    it 'should_not_define_singular_without_scope' do
      assert !klass.respond_to?(:without_state)
    end

    it 'should_not_define_plural_with_scope' do
      assert !klass.respond_to?(:with_states)
    end

    it 'should_not_define_plural_without_scope' do
      assert !klass.respond_to?(:without_states)
    end

    it 'should_extend_owner_class_with_class_methods' do
      assert((
             class << klass
               ancestors
             end).include?(StateMachines::ClassMethods))
    end

    it 'should_include_instance_methods_in_owner_class' do
      assert klass.included_modules.include?(StateMachines::InstanceMethods)
    end

    it 'should_define_state_machines_reader' do
      expected = {state: machine}
      assert_equal expected, klass.state_machines
    end

    it 'should_raise_exception_if_invalid_option_specified ' do
      assert_raise(ArgumentError) { StateMachines::Machine.new(Class.new, invalid: true) }
    end

    it 'should_not_raise_exception_if_custom_messages_specified ' do
      assert_nothing_raised { StateMachines::Machine.new(Class.new, messages: {invalid_transition: 'Custom'}) }
    end

    it 'should_evaluate_a_block_during_initialization ' do
      called = true
      StateMachines::Machine.new(Class.new) do
        called = respond_to?(:event)
      end

      assert called
    end

    it 'should_provide_matcher_helpers_during_initialization ' do
      matchers = []

      StateMachines::Machine.new(Class.new) do
        matchers = [all, any, same]
      end

      assert_equal [StateMachines::AllMatcher.instance, StateMachines::AllMatcher.instance, StateMachines::LoopbackMatcher.instance], matchers
    end


  end


  context 'Drawing' do
    it 'should raise NotImplementedError' do
      machine = StateMachines::Machine.new(Class.new)
      expect { machine.draw(:foo) }.to raise_error(NotImplementedError)
    end
  end


  context 'WithCustomName' do
    let!(:machine) { StateMachines::Machine.new(klass, :status) }
    it 'should_use_custom_name' do
      assert_equal :status, machine.name
    end

    it 'should_use_custom_name_for_attribute' do
      assert_equal :status, machine.attribute
    end

    it 'should_prefix_custom_attributes_with_custom_name' do
      assert_equal :status_event, machine.attribute(:event)
    end

    it 'should_define_a_reader_attribute_for_the_attribute' do
      assert object.respond_to?(:status)
    end

    it 'should_define_a_writer_attribute_for_the_attribute' do
      assert object.respond_to?(:status=)
    end

    it 'should_define_a_predicate_for_the_attribute' do
      assert object.respond_to?(:status?)
    end

    it 'should_define_a_name_reader_for_the_attribute' do
      assert object.respond_to?(:status_name)
    end

    it 'should_define_an_event_reader_for_the_attribute' do
      assert object.respond_to?(:status_events)
    end

    it 'should_define_a_transition_reader_for_the_attribute' do
      assert object.respond_to?(:status_transitions)
    end

    it 'should_define_an_event_runner_for_the_attribute' do
      assert object.respond_to?(:fire_status_event)
    end

    it 'should_define_a_human_attribute_name_reader_for_the_attribute' do
      assert klass.respond_to?(:human_status_name)
    end

    it 'should_define_a_human_event_name_reader_for_the_attribute' do
      assert klass.respond_to?(:human_status_event_name)
    end
  end

  context 'WithoutInitialization' do
    let(:klass) do
      Class.new do
        def initialize(attributes = {})
          attributes.each { |attr, value| send("#{attr}=", value) }
          super()
        end
      end
    end

    let!(:machine) { StateMachines::Machine.new(klass, initial: :parked, initialize: false) }

    it 'should_not_have_an_initial_state' do
      object = klass.new
      assert_nil object.state
    end

    it 'should_still_allow_manual_initialization' do
      klass.send(:include, Module.new do
        def initialize(attributes = {})
          super()
          initialize_state_machines
        end
      end)

      object = klass.new
      assert_equal 'parked', object.state
    end
  end

  context 'WithStaticInitialState' do
    let!(:machine) { StateMachines::Machine.new(klass, initial: :parked) }

    it 'should_not_have_dynamic_initial_state' do
      assert !machine.dynamic_initial_state?
    end

    it 'should_have_an_initial_state' do
      object = klass.new
      assert_equal 'parked', machine.initial_state(object).value
    end

    it 'should_write_to_attribute_when_initializing_state' do
      object = klass.allocate
      machine.initialize_state(object)
      assert_equal 'parked', object.state
    end

    it 'should_set_initial_on_state_object' do
      assert machine.state(:parked).initial
    end

    it 'should_set_initial_state_on_created_object' do
      assert_equal 'parked', klass.new.state
    end

    it 'not_set_initial_state_even_if_not_empty' do
      klass.class_eval do
        def initialize(attributes = {})
          self.state = 'idling'
          super()
        end
      end
      object = klass.new
      assert_equal 'idling', object.state
    end

    it 'should_set_initial_state_prior_to_initialization' do
      base = Class.new do
        attr_accessor :state_on_init

        def initialize
          self.state_on_init = state
        end
      end
      klass = Class.new(base)
      StateMachines::Machine.new(klass, initial: :parked)

      assert_equal 'parked', klass.new.state_on_init
    end

    it 'should_be_included_in_known_states' do
      assert_equal [:parked], machine.states.keys
    end
  end

  context 'WithInitialStateWithValueAndOwnerDefault' do
    before(:each) do
      @original_stderr, $stderr = $stderr, StringIO.new

    end
    let(:state_machine_with_defaults) do
      Class.new(StateMachines::Machine) do
        def owner_class_attribute_default
          0
        end
      end
    end

    it 'should_not_warn_about_wrong_default ' do
      state_machine_with_defaults.new(klass, initial: :parked) do
        state :parked, value: 0
      end
      expect($stderr.string).to be_empty
    end

    it 'should_warn_about_wrong_default ' do
      state_machine_with_defaults.new(klass, initial: :parked) do
        state :parked, value: 666
      end
      expect($stderr.string).to_not be_empty
    end

    after(:each) do
      $stderr = @original_stderr
    end
  end

  context 'WithDynamicInitialState ' do
    let(:klass) do
      Class.new do
        attr_accessor :initial_state
      end
    end

    let!(:machine) do
      machine = StateMachines::Machine.new(klass, initial: lambda { |object| object.initial_state || :default })
      machine.state :parked, :idling, :default
      machine
    end

    it 'should_have_dynamic_initial_state ' do
      assert machine.dynamic_initial_state?
    end

    it 'should_use_the_record_for_determining_the_initial_state ' do
      object.initial_state = :parked
      assert_equal :parked, machine.initial_state(object).name

      object.initial_state = :idling
      assert_equal :idling, machine.initial_state(object).name
    end

    it 'should_write_to_attribute_when_initializing_state ' do
      object = klass.allocate
      object.initial_state = :parked
      machine.initialize_state(object)
      assert_equal 'parked', object.state
    end

    it 'should_set_initial_state_on_created_object ' do
      assert_equal 'default', object.state
    end

    it 'should_not_set_initial_state_even_if_not_empty ' do
      klass.class_eval do
        def initialize(attributes = {})
          self.state = 'parked'
          super()
        end
      end
      object = klass.new
      assert_equal 'parked', object.state
    end

    it 'should_set_initial_state_after_initialization ' do
      base = Class.new do
        attr_accessor :state_on_init

        def initialize
          self.state_on_init = state
        end
      end
      klass = Class.new(base)
      machine = StateMachines::Machine.new(klass, initial: lambda { |object| :parked })
      machine.state :parked

      assert_nil klass.new.state_on_init
    end

    it 'should_not_be_included_in_known_states ' do
      assert_equal [:parked, :idling, :default], machine.states.map { |state| state.name }
    end
  end

  context 'stateInitialization ' do
    let!(:machine) { StateMachines::Machine.new(klass, :state, initial: :parked, initialize: false) }
    before(:each) do
      object.state = nil
    end

    it 'should_set_states_if_nil ' do
      machine.initialize_state(object)

      assert_equal 'parked', object.state
    end

    it 'should_set_states_if_empty ' do
      object.state = ''
      machine.initialize_state(object)

      assert_equal 'parked', object.state
    end

    it 'should_not_set_states_if_not_empty ' do
      object.state = 'idling'
      machine.initialize_state(object)

      assert_equal 'idling', object.state
    end

    it 'should_set_states_if_not_empty_and_forced ' do
      object.state = 'idling'
      machine.initialize_state(object, force: true)

      assert_equal 'parked', object.state
    end

    it 'should_not_set_state_if_nil_and_nil_is_valid_state ' do
      machine.state :initial, value: nil
      machine.initialize_state(object)

      assert_nil object.state
    end

    it 'should_write_to_hash_if_specified ' do
      machine.initialize_state(object, to: hash = {})
      assert_equal({'state' => 'parked'}, hash)
    end

    it 'should_not_write_to_object_if_writing_to_hash ' do
      machine.initialize_state(object, to: {})
      assert_nil object.state
    end
  end

  context 'WithCustomAction' do
    let(:machine) { StateMachines::Machine.new(Class.new, action: :save) }

    it 'should_use_the_custom_action ' do
      assert_equal :save, machine.action
    end
  end

  context 'WithNilAction' do
    let!(:machine) { StateMachines::Machine.new(Class.new, action: nil, integration: :custom) }
    before(:all) do
      integration = Module.new do
        include StateMachines::Integrations::Base

        @defaults = {action: :save}
      end
      StateMachines::Integrations.const_set('Custom', integration)
    end

    it 'should_have_a_nil_action ' do
      assert_nil machine.action
    end

    after(:all) do
      StateMachines::Integrations.send(:remove_const, 'Custom')
      StateMachines::Integrations.send(:reset)
    end
  end

  context 'WithoutIntegration' do
    it ' transaction_should_yield ' do
      yielded = false
      machine.within_transaction(object) do
        yielded = true
      end

      assert yielded
    end

    it ' invalidation_should_do_nothing ' do
      assert_nil machine.invalidate(object, :state, :invalid_transition, [[:event, ' park ']])
    end

    it ' reset_should_do_nothing ' do
      assert_nil machine.reset(object)
    end

    it ' errors_for_should_be_empty ' do
      assert_equal '', machine.errors_for(object)
    end
  end

  context 'WithCustomIntegration' do
    before(:each) do
      integration = Module.new do
        include StateMachines::Integrations::Base

        def self.matching_ancestors
          ['Vehicle']
        end
      end

      StateMachines::Integrations.const_set('Custom', integration)

      superclass = Class.new
      self.class.const_set('Vehicle', superclass)

      @klass = Class.new(superclass)
    end

    it 'should_be_extended_by_the_integration_if_explicit' do
      machine = StateMachines::Machine.new(@klass, :integration => :custom)
      assert((class << machine; ancestors; end).include?(StateMachines::Integrations::Custom))
    end

    it 'should_not_be_extended_by_the_integration_if_implicit_but_not_available' do
      StateMachines::Integrations::Custom.class_eval do
        class << self; remove_method :matching_ancestors; end
        def self.matching_ancestors
          []
        end
      end

      machine = StateMachines::Machine.new(@klass)
      assert(!(class << machine; ancestors; end).include?(StateMachines::Integrations::Custom))
    end

    it 'should_not_be_extended_by_the_integration_if_implicit_but_not_matched' do
      StateMachines::Integrations::Custom.class_eval do
        class << self; remove_method :matching_ancestors; end
        def self.matching_ancestors
          []
        end
      end

      machine = StateMachines::Machine.new(@klass)
      assert(!(class << machine; ancestors; end).include?(StateMachines::Integrations::Custom))
    end

    xit 'should_be_extended_by_the_integration_if_implicit_and_available_and_matches' do
      machine = StateMachines::Machine.new(@klass)
      assert((class << machine; ancestors; end).include?(StateMachines::Integrations::Custom))
    end

    it 'should_not_be_extended_by_the_integration_if_nil' do
      machine = StateMachines::Machine.new(@klass, :integration => nil)
      assert(!(class << machine; ancestors; end).include?(StateMachines::Integrations::Custom))
    end

    it 'should_not_be_extended_by_the_integration_if_false' do
      machine = StateMachines::Machine.new(@klass, :integration => false)
      assert(!(class << machine; ancestors; end).include?(StateMachines::Integrations::Custom))
    end

    after(:each) do
      self.class.send(:remove_const, 'Vehicle')
      StateMachines::Integrations.send(:remove_const, 'Custom')
      StateMachines::Integrations.send(:reset)
    end
  end

  context 'WithIntegration' do

    before(:each) do
      StateMachines::Integrations.const_set('Custom', Module.new do
        include StateMachines::Integrations::Base

        @defaults = {action: :save, use_transactions: false}

        attr_reader :initialized, :with_scopes, :without_scopes, :ran_transaction

        def after_initialize
          @initialized = true
        end

        def create_with_scope(name)
          (@with_scopes ||= []) << name
          lambda {}
        end

        def create_without_scope(name)
          (@without_scopes ||= []) << name
          lambda {}
        end

        def transaction(object)
          @ran_transaction = true
          yield
        end
      end)

    end

    let(:machine) { StateMachines::Machine.new(Class.new, integration: :custom) }

    it 'should_call_after_initialize_hook ' do
      assert machine.initialized
    end

    it 'should_use_the_default_action ' do
      assert_equal :save, machine.action
    end

    it 'should_use_the_custom_action_if_specified ' do
      machine = StateMachines::Machine.new(Class.new, integration: :custom, action: :save!)
      assert_equal :save!, machine.action
    end

    it 'should_use_the_default_use_transactions ' do
      assert_equal false, machine.use_transactions
    end

    it 'should_use_the_custom_use_transactions_if_specified ' do
      machine = StateMachines::Machine.new(Class.new, integration: :custom, use_transactions: true)
      assert_equal true, machine.use_transactions
    end

    it 'should_define_a_singular_and_plural_with_scope ' do
      assert_equal %w(with_state with_states), machine.with_scopes
    end

    it 'should_define_a_singular_and_plural_without_scope ' do
      assert_equal %w(without_state without_states), machine.without_scopes
    end

    after(:each) do
      StateMachines::Integrations.send(:remove_const, 'Custom')
      StateMachines::Integrations.send(:reset)
    end
  end

  context 'WithActionUndefined' do
    let!(:machine) { StateMachines::Machine.new(klass, action: :save) }

    it 'should_define_an_event_attribute_reader ' do
      assert object.respond_to?(:state_event)
    end

    it 'should_define_an_event_attribute_writer ' do
      assert object.respond_to?(:state_event=)
    end

    it 'should_define_an_event_transition_attribute_reader ' do
      assert object.respond_to?(:state_event_transition, true)
    end

    it 'should_define_an_event_transition_attribute_writer ' do
      assert object.respond_to?(:state_event_transition=, true)
    end

    it 'should_not_define_action ' do
      assert !object.respond_to?(:save)
    end

    it 'should_not_mark_action_hook_as_defined ' do
      assert !machine.action_hook?
    end
  end

  context 'WithActionDefinedInClass' do
    let(:klass) do
      Class.new do
        def save
        end
      end
    end

    let!(:machine) { StateMachines::Machine.new(klass, action: :save) }

    it 'should_define_an_event_attribute_reader ' do
      assert object.respond_to?(:state_event)
    end

    it 'should_define_an_event_attribute_writer ' do
      assert object.respond_to?(:state_event=)
    end

    it 'should_define_an_event_transition_attribute_reader ' do
      assert object.respond_to?(:state_event_transition, true)
    end

    it 'should_define_an_event_transition_attribute_writer ' do
      assert object.respond_to?(:state_event_transition=, true)
    end

    it 'should_not_define_action ' do
      assert !klass.ancestors.any? { |ancestor| ancestor != klass && ancestor.method_defined?(:save) }
    end

    it 'should_not_mark_action_hook_as_defined ' do
      assert !machine.action_hook?
    end
  end

  context 'WithActionDefinedInIncludedModule' do
    before(:each) do

      @mod = mod =   Module.new do
        def save
        end
      end
      @klass =  Class.new do
        include mod
      end
      @machine = StateMachines::Machine.new(@klass, action: :save)
      @object = @klass.new
    end



    it 'should_define_an_event_attribute_reader ' do
      assert @object.respond_to?(:state_event)
    end

    it 'should_define_an_event_attribute_writer ' do
      assert @object.respond_to?(:state_event=)
    end

    it 'should_define_an_event_transition_attribute_reader ' do
      assert @object.respond_to?(:state_event_transition, true)
    end

    it 'should_define_an_event_transition_attribute_writer ' do
      assert @object.respond_to?(:state_event_transition=, true)
    end

    it 'should_define_action ' do
      assert @klass.ancestors.any? { |ancestor| ![@klass, @mod].include?(ancestor) && ancestor.method_defined?(:save) }
    end

    it 'should_keep_action_public ' do
      assert @klass.public_method_defined?(:save)
    end

    it 'should_mark_action_hook_as_defined ' do
      assert @machine.action_hook?
    end
  end

  context 'WithActionDefinedInSuperclass' do
    let(:superclass) do
      Class.new do
        def save
        end
      end
    end
    let(:klass) { Class.new(superclass) }
    let!(:machine) { StateMachines::Machine.new(klass, action: :save) }

    it 'should_define_an_event_attribute_reader ' do
      assert object.respond_to?(:state_event)
    end

    it 'should_define_an_event_attribute_writer ' do
      assert object.respond_to?(:state_event=)
    end

    it 'should_define_an_event_transition_attribute_reader ' do
      assert object.respond_to?(:state_event_transition, true)
    end

    it 'should_define_an_event_transition_attribute_writer ' do
      assert object.respond_to?(:state_event_transition=, true)
    end

    it 'should_define_action ' do
      assert klass.ancestors.any? { |ancestor| ![klass, superclass].include?(ancestor) && ancestor.method_defined?(:save) }
    end

    it 'should_keep_action_public ' do
      assert klass.public_method_defined?(:save)
    end

    it 'should_mark_action_hook_as_defined ' do
      assert machine.action_hook?
    end
  end

  context 'WithPrivateAction' do

    let(:superclass) do
      Class.new do
        private
        def save
        end
      end
    end
    let(:klass) { Class.new(superclass) }
    let!(:machine) { StateMachines::Machine.new(klass, action: :save) }

    it 'should_define_an_event_attribute_reader ' do
      assert object.respond_to?(:state_event)
    end

    it 'should_define_an_event_attribute_writer ' do
      assert object.respond_to?(:state_event=)
    end

    it 'should_define_an_event_transition_attribute_reader ' do
      assert object.respond_to?(:state_event_transition, true)
    end

    it 'should_define_an_event_transition_attribute_writer ' do
      assert object.respond_to?(:state_event_transition=, true)
    end

    it 'should_define_action ' do
      assert klass.ancestors.any? { |ancestor| ![klass, superclass].include?(ancestor) && ancestor.private_method_defined?(:save) }
    end

    it 'should_keep_action_private ' do
      assert klass.private_method_defined?(:save)
    end

    it 'should_mark_action_hook_as_defined ' do
      assert machine.action_hook?
    end
  end

  context 'WithActionAlreadyOverridden' do

    before(:each) do
      @superclass = Class.new do
        def save
        end
      end
      @klass = Class.new(@superclass)

      StateMachines::Machine.new(@klass, :action => :save)
      @machine = StateMachines::Machine.new(@klass, :status, :action => :save)
      @object = @klass.new
    end

    it 'should_not_redefine_action ' do
      assert_equal 1, @klass.ancestors.select { |ancestor| ![@klass, @superclass].include?(ancestor) && ancestor.method_defined?(:save) }.length
    end

    it 'should_mark_action_hook_as_defined ' do
      assert @machine.action_hook?
    end
  end

  context 'WithCustomPlural' do

    before(:each)   do
      @integration = Module.new do
        include StateMachines::Integrations::Base

        class << self; attr_accessor :with_scopes, :without_scopes; end
        @with_scopes = []
        @without_scopes = []

        def create_with_scope(name)
          StateMachines::Integrations::Custom.with_scopes << name
          lambda {}
        end

        def create_without_scope(name)
          StateMachines::Integrations::Custom.without_scopes << name
          lambda {}
        end
      end

      StateMachines::Integrations.const_set('Custom', @integration)
    end


    it 'should_define_a_singular_and_plural_with_scope' do
      StateMachines::Machine.new(Class.new, :integration => :custom, :plural => 'staties')
      assert_equal %w(with_state with_staties), @integration.with_scopes
    end

    it 'should_define_a_singular_and_plural_without_scope' do
      StateMachines::Machine.new(Class.new, :integration => :custom, :plural => 'staties')
      assert_equal %w(without_state without_staties), @integration.without_scopes
    end

    it 'should_define_single_with_scope_if_singular_same_as_plural' do
      StateMachines::Machine.new(Class.new, :integration => :custom, :plural => 'state')
      assert_equal %w(with_state), @integration.with_scopes
    end

    it 'should_define_single_without_scope_if_singular_same_as_plural' do
      StateMachines::Machine.new(Class.new, :integration => :custom, :plural => 'state')
      assert_equal %w(without_state), @integration.without_scopes
    end

    after(:each) do
      StateMachines::Integrations.send(:remove_const, 'Custom')
      StateMachines::Integrations.send(:reset)
    end
  end

  context 'WithCustomInvalidation' do
    let!(:integration) do
      integration = Module.new do
        include StateMachines::Integrations::Base

        def invalidate(object, attribute, message, values = [])
          object.error = generate_message(message, values)
        end
      end
      StateMachines::Integrations.const_set('Custom', integration)
      integration
    end

    let!(:klass) do
      Class.new do
        attr_accessor :error
      end
    end

    let!(:machine) do
      machine = StateMachines::Machine.new(klass, integration: :custom, messages: {invalid_transition: 'cannot %s'})
      machine.state :parked
      machine
    end

    before(:each) do

      object.state = 'parked'
    end

    it ' generate_custom_message ' do
      assert_equal 'cannot park', machine.generate_message(:invalid_transition, [[:event, :park]])
    end

    it ' use_custom_message ' do
      machine.invalidate(object, :state, :invalid_transition, [[:event, 'park']])
      assert_equal 'cannot park', object.error
    end

    after(:each) do
      StateMachines::Integrations.send(:remove_const, 'Custom')
      StateMachines::Integrations.send(:reset)
    end
  end

  context 'AfterBeingCopied' do
    before(:each) do
      @machine = StateMachines::Machine.new(Class.new, :state, initial: :parked)
      @machine.event(:ignite) {}
      @machine.before_transition(lambda {})
      @machine.after_transition(lambda {})
      @machine.around_transition(lambda {})
      @machine.after_failure(lambda {})
      @copied_machine = @machine.clone
    end

    it 'should_not_have_the_same_collection_of_states ' do
      assert_not_same @copied_machine.states, @machine.states
    end

    it 'should_copy_each_state ' do
      assert_not_same @copied_machine.states[:parked], @machine.states[:parked]
    end

    it 'should_update_machine_for_each_state ' do
      assert_equal @copied_machine, @copied_machine.states[:parked].machine
    end

    it 'should_not_update_machine_for_original_state ' do
      assert_equal @machine, @machine.states[:parked].machine
    end

    it 'should_not_have_the_same_collection_of_events ' do
      assert_not_same @copied_machine.events, @machine.events
    end

    it 'should_copy_each_event ' do
      assert_not_same @copied_machine.events[:ignite], @machine.events[:ignite]
    end

    it 'should_update_machine_for_each_event ' do
      assert_equal @copied_machine, @copied_machine.events[:ignite].machine
    end

    it 'should_not_update_machine_for_original_event ' do
      assert_equal @machine, @machine.events[:ignite].machine
    end

    it 'should_not_have_the_same_callbacks ' do
      assert_not_same @copied_machine.callbacks, @machine.callbacks
    end

    it 'should_not_have_the_same_before_callbacks ' do
      assert_not_same @copied_machine.callbacks[:before], @machine.callbacks[:before]
    end

    it 'should_not_have_the_same_after_callbacks ' do
      assert_not_same @copied_machine.callbacks[:after], @machine.callbacks[:after]
    end

    it 'should_not_have_the_same_failure_callbacks ' do
      assert_not_same @copied_machine.callbacks[:failure], @machine.callbacks[:failure]
    end
  end

  context 'AfterChangingOwnerClass' do
    let(:original_class) { Class.new }
    let(:machine) { StateMachines::Machine.new(original_class) }
    let(:new_class) { Class.new(original_class) }
    let(:new_machine) do
      new_machine = machine.clone
      new_machine.owner_class = new_class
      new_machine
    end
    let(:object) { new_class.new }

    it 'should_update_owner_class ' do
      assert_equal new_class, new_machine.owner_class
    end

    it 'should_not_change_original_owner_class ' do
      assert_equal original_class, machine.owner_class
    end

    it 'should_change_the_associated_machine_in_the_new_class ' do
      assert_equal new_machine, new_class.state_machines[:state]
    end

    it 'should_not_change_the_associated_machine_in_the_original_class ' do
      assert_equal machine, original_class.state_machines[:state]
    end
  end

  context 'AfterChangingInitialState' do
    let(:machine) do
      machine = StateMachines::Machine.new(klass, initial: :parked)
      machine.initial_state = :idling
      machine
    end

    it 'should_change_the_initial_state' do
      assert_equal :idling, machine.initial_state(object).name
    end

    it 'should_include_in_known_states' do
      assert_equal [:parked, :idling], machine.states.map { |state| state.name }
    end

    it 'should_reset_original_initial_state' do
      assert !machine.state(:parked).initial
    end

    it 'should_set_new_state_to_initial' do
      assert machine.state(:idling).initial
    end
  end

  context 'WithHelpers' do
    it 'should_throw_exception_with_invalid_scope' do
      assert_raise(RUBY_VERSION < '1.9' ? IndexError : KeyError) { machine.define_helper(:invalid, :park) {} }
    end
  end

  context 'WithInstanceHelpers' do
    before(:each) do
      @original_stderr, $stderr = $stderr, StringIO.new

      @klass = Class.new
      @machine = StateMachines::Machine.new(@klass)
      @object = @klass.new
    end

    it 'should_not_redefine_existing_public_methods' do
      @klass.class_eval do
        def park
          true
        end
      end

      @machine.define_helper(:instance, :park) {}
      assert_equal true, @object.park
    end

    it 'should_not_redefine_existing_protected_methods' do
      @klass.class_eval do
        protected
        def park
          true
        end
      end

      @machine.define_helper(:instance, :park) {}
      assert_equal true, @object.send(:park)
    end

    it 'should_not_redefine_existing_private_methods' do
      @klass.class_eval do
        private
        def park
          true
        end
      end

      @machine.define_helper(:instance, :park) {}
      assert_equal true, @object.send(:park)
    end

    it 'should_warn_if_defined_in_superclass' do
      superclass = Class.new do
        def park
        end
      end
      @klass = Class.new(superclass)
      @machine = StateMachines::Machine.new(@klass)

      @machine.define_helper(:instance, :park) {}
      assert_equal "Instance method \"park\" is already defined in #{superclass}, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string
    end

    it 'should_warn_if_defined_in_multiple_superclasses' do
      superclass1 = Class.new do
        def park
        end
      end
      superclass2 = Class.new(superclass1) do
        def park
        end
      end
      @klass = Class.new(superclass2)
      @machine = StateMachines::Machine.new(@klass)

      @machine.define_helper(:instance, :park) {}
      assert_equal "Instance method \"park\" is already defined in #{superclass1}, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string
    end

    it 'should_warn_if_defined_in_module_prior_to_helper_module' do
      mod = Module.new do
        def park
        end
      end
      @klass = Class.new do
        include mod
      end
      @machine = StateMachines::Machine.new(@klass)

      @machine.define_helper(:instance, :park) {}
      assert_equal "Instance method \"park\" is already defined in #{mod}, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string
    end

    it 'should_not_warn_if_defined_in_module_after_helper_module' do
      klass = Class.new
      StateMachines::Machine.new(klass)

      mod = Module.new do
        def park
        end
      end
      @klass.class_eval do
        extend mod
      end

      @machine.define_helper(:instance, :park) {}
      assert_equal '', $stderr.string
    end

    it 'should_define_if_ignoring_method_conflicts_and_defined_in_superclass' do

      StateMachines::Machine.ignore_method_conflicts = true

      superclass = Class.new do
        def park
        end
      end
      @klass = Class.new(superclass)
      @machine = StateMachines::Machine.new(@klass)

      @machine.define_helper(:instance, :park) { true }
      assert_equal '', $stderr.string
      assert_equal true, @klass.new.park

    end

    it 'should_define_nonexistent_methods' do
      @machine.define_helper(:instance, :park) { false }
      assert_equal false, @object.park
    end

    it 'should_warn_if_defined_multiple_times' do
      @machine.define_helper(:instance, :park) {}
      @machine.define_helper(:instance, :park) {}

      assert_equal "Instance method \"park\" is already defined in #{@klass} :state instance helpers, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string

    end

    it 'should_pass_context_as_arguments' do
      helper_args = nil
      @machine.define_helper(:instance, :park) { |*args| helper_args = args }
      @object.park
      assert_equal 2, helper_args.length
      assert_equal [@machine, @object], helper_args
    end

    it 'should_pass_method_arguments_through' do
      helper_args = nil
      @machine.define_helper(:instance, :park) { |*args| helper_args = args }
      @object.park(1, 2, 3)
      assert_equal 5, helper_args.length
      assert_equal [@machine, @object, 1, 2, 3], helper_args
    end

    it 'should_allow_string_evaluation' do
      @machine.define_helper :instance, <<-end_eval, __FILE__, __LINE__ + 1
      def park
        false
      end
      end_eval
      assert_equal false, @object.park
    end


    after(:each) do
      StateMachines::Machine.ignore_method_conflicts = false
      $stderr = @original_stderr
    end
  end

  context 'WithClassHelpers' do
    before(:each) do
      @original_stderr, $stderr = $stderr, StringIO.new
    end

    it 'should_not_redefine_existing_public_methods' do
      class << klass
        def states
          []
        end
      end

      machine.define_helper(:class, :states) {}
      assert_equal [], klass.states
    end

    it 'should_not_redefine_existing_protected_methods' do
      class << klass
        protected
        def states
          []
        end
      end

      machine.define_helper(:class, :states) {}
      assert_equal [], klass.send(:states)
    end

    it 'should_not_redefine_existing_private_methods' do
      class << klass
        private
        def states
          []
        end
      end

      machine.define_helper(:class, :states) {}
      assert_equal [], klass.send(:states)
    end

    it 'should_warn_if_defined_in_superclass' do

      

      superclass = Class.new do
        def self.park
        end
      end
      klass = Class.new(superclass)
      machine = StateMachines::Machine.new(klass)

      machine.define_helper(:class, :park) {}
      assert_equal "Class method \"park\" is already defined in #{superclass}, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string
      # ensure
      $stderr = @original_stderr
    end

    it 'should_warn_if_defined_in_multiple_superclasses' do

      superclass1 = Class.new do
        def self.park
        end
      end
      superclass2 = Class.new(superclass1) do
        def self.park
        end
      end
      klass = Class.new(superclass2)
      machine = StateMachines::Machine.new(klass)

      machine.define_helper(:class, :park) {}
      assert_equal "Class method \"park\" is already defined in #{superclass1}, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string

    end

    it 'should_warn_if_defined_in_module_prior_to_helper_module' do

      

      mod = Module.new do
        def park
        end
      end
      klass = Class.new do
        extend mod
      end
      machine = StateMachines::Machine.new(klass)

      machine.define_helper(:class, :park) {}
      assert_equal "Class method \"park\" is already defined in #{mod}, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string
      # ensure

    end


    it 'should_not_warn_if_defined_in_module_after_helper_module' do

      


      machine = StateMachines::Machine.new(klass)

      mod = Module.new do
        def park
        end
      end
      klass.class_eval do
        extend mod
      end

      machine.define_helper(:class, :park) {}
      assert_equal '', $stderr.string
      # ensure
      $stderr = @original_stderr
    end

    it 'should_define_if_ignoring_method_conflicts_and_defined_in_superclass' do

      
      StateMachines::Machine.ignore_method_conflicts = true

      superclass = Class.new do
        def self.park
        end
      end
      klass = Class.new(superclass)
      machine = StateMachines::Machine.new(klass)

      machine.define_helper(:class, :park) { true }
      assert_equal '', $stderr.string
      assert_equal true, klass.park
      # ensure
      StateMachines::Machine.ignore_method_conflicts = false
      $stderr = @original_stderr
    end

    it 'should_define_nonexistent_methods' do
      machine.define_helper(:class, :states) { [] }
      assert_equal [], klass.states
    end

    it 'should_warn_if_defined_multiple_times' do

      

      machine.define_helper(:class, :states) {}
      machine.define_helper(:class, :states) {}

      assert_equal "Class method \"states\" is already defined in #{klass} :state class helpers, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string
      # ensure
      $stderr = @original_stderr
    end

    it 'should_pass_context_as_arguments' do
      helper_args = nil
      machine.define_helper(:class, :states) { |*args| helper_args = args }
      klass.states
      assert_equal 2, helper_args.length
      assert_equal [machine, klass], helper_args
    end

    it 'should_pass_method_arguments_through' do
      helper_args = nil
      machine.define_helper(:class, :states) { |*args| helper_args = args }
      klass.states(1, 2, 3)
      assert_equal 5, helper_args.length
      assert_equal [machine, klass, 1, 2, 3], helper_args
    end

    it 'should_allow_string_evaluation' do
      machine.define_helper :class, <<-end_eval, __FILE__, __LINE__ + 1
      def states
        []
      end
      end_eval
      assert_equal [], klass.states
    end

    after(:each)  do
      $stderr = @original_stderr
    end
  end

  context 'WithConflictingHelpersBeforeDefinition' do

    before(:each) do
      @original_stderr, $stderr = $stderr, StringIO.new

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
          [{:parked => :idling}]
        end

        def state_paths
          [[{:parked => :idling}]]
        end

        def fire_state_event
          true
        end
      end
      @klass = Class.new(@superclass)

      StateMachines::Integrations.const_set('Custom', Module.new do
        include StateMachines::Integrations::Base

        def create_with_scope(name)
          lambda {|klass, values| []}
        end

        def create_without_scope(name)
          lambda {|klass, values| []}
        end
      end)

      @machine = StateMachines::Machine.new(@klass, :integration => :custom)
      @machine.state :parked, :idling
      @machine.event :ignite
      @object = @klass.new
    end

    it 'should_not_redefine_singular_with_scope' do
      assert_equal :with_state, @klass.with_state
    end

    it 'should_not_redefine_plural_with_scope' do
      assert_equal :with_states, @klass.with_states
    end

    it 'should_not_redefine_singular_without_scope' do
      assert_equal :without_state, @klass.without_state
    end

    it 'should_not_redefine_plural_without_scope' do
      assert_equal :without_states, @klass.without_states
    end

    it 'should_not_redefine_human_attribute_name_reader' do
      assert_equal :human_state_name, @klass.human_state_name
    end

    it 'should_not_redefine_human_event_name_reader' do
      assert_equal :human_state_event_name, @klass.human_state_event_name
    end

    it 'should_not_redefine_attribute_reader' do
      assert_equal 'parked', @object.state
    end

    it 'should_not_redefine_attribute_writer' do
      @object.state = 'parked'
      assert_equal 'parked', @object.status
    end

    it 'should_not_define_attribute_predicate' do
      assert @object.state?
    end

    it 'should_not_redefine_attribute_name_reader' do
      assert_equal :parked, @object.state_name
    end

    it 'should_not_redefine_attribute_human_name_reader' do
      assert_equal 'parked', @object.human_state_name
    end

    it 'should_not_redefine_attribute_events_reader' do
      assert_equal [:ignite], @object.state_events
    end

    it 'should_not_redefine_attribute_transitions_reader' do
      assert_equal [{:parked => :idling}], @object.state_transitions
    end

    it 'should_not_redefine_attribute_paths_reader' do
      assert_equal [[{:parked => :idling}]], @object.state_paths
    end

    it 'should_not_redefine_event_runner' do
      assert_equal true, @object.fire_state_event
    end

    it 'should_output_warning' do
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
      ].map {|method| "#{method} is already defined in #{@superclass.to_s}, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n"}.join

      assert_equal expected, $stderr.string
    end
    
    after(:each) do
      $stderr = @original_stderr
      StateMachines::Integrations.send(:remove_const, 'Custom')
      StateMachines::Integrations.send(:reset)
    end


    
  end

  context 'WithConflictingHelpersAfterDefinition' do
    let(:klass) do
      Class.new do
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
          [{parked: :idling}]
        end

        def state_paths
          [[{parked: :idling}]]
        end

        def fire_state_event
          true
        end
      end
    end

    before(:each) do

      @original_stderr, $stderr = $stderr, StringIO.new

      StateMachines::Integrations.const_set('Custom', Module.new do
        include StateMachines::Integrations::Base

        def create_with_scope(name)
          lambda { |klass, values| [] }
        end

        def create_without_scope(name)
          lambda { |klass, values| [] }
        end
      end)

    end

    after(:each) do
      $stderr = @original_stderr
    end
    let!(:machine) do
      machine = StateMachines::Machine.new(klass, integration: :custom)
      machine.state :parked, :idling
      machine.event :ignite
      machine
    end

    it 'should_not_redefine_singular_with_scope' do
      assert_equal :with_state, klass.with_state
    end

    it 'should_not_redefine_plural_with_scope' do
      assert_equal :with_states, klass.with_states
    end

    it 'should_not_redefine_singular_without_scope' do
      assert_equal :without_state, klass.without_state
    end

    it 'should_not_redefine_plural_without_scope' do
      assert_equal :without_states, klass.without_states
    end

    it 'should_not_redefine_human_attribute_name_reader' do
      assert_equal :human_state_name, klass.human_state_name
    end

    it 'should_not_redefine_human_event_name_reader' do
      assert_equal :human_state_event_name, klass.human_state_event_name
    end

    it 'should_not_redefine_attribute_reader' do
      assert_equal 'parked', object.state
    end

    it 'should_not_redefine_attribute_writer' do
      object.state = 'parked'
      assert_equal 'parked', object.status
    end

    it 'should_not_define_attribute_predicate' do
      assert object.state?
    end

    it 'should_not_redefine_attribute_name_reader' do
      assert_equal :parked, object.state_name
    end

    it 'should_not_redefine_attribute_human_name_reader' do
      assert_equal 'parked', object.human_state_name
    end

    it 'should_not_redefine_attribute_events_reader' do
      assert_equal [:ignite], object.state_events
    end

    it 'should_not_redefine_attribute_transitions_reader' do
      assert_equal [{parked: :idling}], object.state_transitions
    end

    it 'should_not_redefine_attribute_paths_reader' do
      assert_equal [[{parked: :idling}]], object.state_paths
    end

    it 'should_not_redefine_event_runner' do
      assert_equal true, object.fire_state_event
    end

    it 'should_allow_super_chaining' do
      klass.class_eval do
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

      assert_equal [], klass.with_state
      assert_equal [], klass.with_states
      assert_equal [], klass.without_state
      assert_equal [], klass.without_states
      assert_equal 'parked', klass.human_state_name(:parked)
      assert_equal 'ignite', klass.human_state_event_name(:ignite)

      assert_equal nil, object.state
      object.state = 'idling'
      assert_equal 'idling', object.state
      assert_equal nil, object.status
      assert_equal false, object.state?(:parked)
      assert_equal :idling, object.state_name
      assert_equal 'idling', object.human_state_name
      assert_equal [], object.state_events
      assert_equal [], object.state_transitions
      assert_equal [], object.state_paths
      assert_equal false, object.fire_state_event(:ignite)
    end

    it 'should_not_output_warning' do
      assert_equal '', $stderr.string
    end

    after(:each) do
      $stderr = @original_stderr
      StateMachines::Integrations.send(:remove_const, 'Custom')
      StateMachines::Integrations.send(:reset)
    end
  end

  context 'WithSuperclassConflictingHelpersAfterDefinition' do
    before(:each) do
      @original_stderr, $stderr = $stderr, StringIO.new

      @superclass = Class.new
      @klass = Class.new(@superclass)

      @machine = StateMachines::Machine.new(@klass)
      @machine.state :parked, :idling
      @machine.event :ignite

      @superclass.class_eval do
        def state?
          true
        end
      end

      @object = @klass.new
    end



    it 'should_call_superclass_attribute_predicate_without_arguments' do
      expect(@object.state?).to be_truthy
    end

    it 'should_define_attribute_predicate_with_arguments' do
      expect(@object.state?(:parked)).to be_falsy
    end

    after(:each) do
      $stderr = @original_stderr
    end
  end

  context 'WithoutInitialize' do
    let!(:machine) { StateMachines::Machine.new(klass, initial: :parked) }

    it 'should_initialize_state' do
      assert_equal 'parked', object.state
    end
  end

  context 'WithInitializeWithoutSuper' do
    let(:klass) do
      Class.new do
        def initialize
        end
      end
    end
    let!(:machine) { StateMachines::Machine.new(klass, initial: :parked) }


    it 'should_not_initialize_state' do
      assert_nil object.state
    end
  end

  context 'WithInitializeAndSuper' do
    let(:klass) do
      Class.new do
        def initialize
          super
        end
      end
    end
    let!(:machine) { StateMachines::Machine.new(klass, initial: :parked) }


    it 'should_initialize_state' do
      assert_equal 'parked', object.state
    end
  end

  context 'WithInitializeArgumentsAndBlock' do
    let(:superclass) do
      Class.new do
        attr_reader :args
        attr_reader :block_given

        def initialize(*args)
          @args = args
          @block_given = block_given?
        end
      end
    end

    let(:klass) { Class.new(superclass) }
    let!(:machine) { StateMachines::Machine.new(klass, initial: :parked) }
    let(:object) { klass.new(1, 2, 3) {} }

    it 'should_initialize_state' do
      assert_equal 'parked', object.state
    end

    it 'should_preserve_arguments' do
      assert_equal [1, 2, 3], object.args
    end

    it 'should_preserve_block' do
      assert object.block_given
    end
  end

  context 'WithCustomInitialize' do
    let(:klass) do
      Class.new do
        def initialize(state = nil, options = {})
          @state = state
          initialize_state_machines(options)
        end
      end
    end
    let!(:machine) { StateMachines::Machine.new(klass, initial: :parked) }


    it 'should_initialize_state' do
      assert_equal 'parked', object.state
    end

    it 'should_allow_custom_options' do
      machine.state :idling
      object = klass.new('idling', static: :force)
      assert_equal 'parked', object.state
    end
  end

  context 'Persistence' do
    let(:klass) do
      Class.new do
        attr_accessor :state_event
      end
    end
    let!(:machine) { StateMachines::Machine.new(klass, initial: :parked) }


    it 'should_allow_reading_state' do
      assert_equal 'parked', machine.read(object, :state)
    end

    it 'should_allow_reading_custom_attributes' do
      assert_nil machine.read(object, :event)

      object.state_event = 'ignite'
      assert_equal 'ignite', machine.read(object, :event)
    end

    it 'should_allow_reading_custom_instance_variables' do
      klass.class_eval do
        attr_writer :state_value
      end

      object.state_value = 1
      assert_raise(NoMethodError) { machine.read(object, :value) }
      assert_equal 1, machine.read(object, :value, true)
    end

    it 'should_allow_writing_state' do
      machine.write(object, :state, 'idling')
      assert_equal 'idling', object.state
    end

    it 'should_allow_writing_custom_attributes' do
      machine.write(object, :event, 'ignite')
      assert_equal 'ignite', object.state_event
    end

    it 'should_allow_writing_custom_instance_variables' do
      klass.class_eval do
        attr_reader :state_value
      end

      assert_raise(NoMethodError) { machine.write(object, :value, 1) }
      assert_equal 1, machine.write(object, :value, 1, true)
      assert_equal 1, object.state_value
    end
  end

  context 'WithStates' do
    before(:each) do
      @parked, @idling = machine.state :parked, :idling
    end

    it 'should_have_states' do
      assert_equal [nil, :parked, :idling], machine.states.map { |state| state.name }
    end

    it 'should_allow_state_lookup_by_name' do
      assert_equal @parked, machine.states[:parked]
    end

    it 'should_allow_state_lookup_by_value' do
      assert_equal @parked, machine.states['parked', :value]
    end

    it 'should_allow_human_state_name_lookup' do
      assert_equal 'parked', klass.human_state_name(:parked)
    end

    it 'should_raise_exception_on_invalid_human_state_name_lookup' do
      assert_raise(IndexError) { klass.human_state_name(:invalid) }
      # FIXME
      #assert_equal ':invalid is an invalid name', exception.message
    end

    it 'should_use_stringified_name_for_value' do
      assert_equal 'parked', @parked.value
    end

    it 'should_not_use_custom_matcher' do
      assert_nil @parked.matcher
    end

    it 'should_raise_exception_if_invalid_option_specified' do
      assert_raise(ArgumentError) { machine.state(:first_gear, invalid: true) }
      # FIXME
      #assert_equal 'Invalid key(s): invalid', exception.message
    end

    it 'should_raise_exception_if_conflicting_type_used_for_name' do
      assert_raise(ArgumentError) { machine.state 'first_gear' }
      # FIXME
      #assert_equal '"first_gear" state defined as String, :parked defined as Symbol; all states must be consistent', exception.message
    end

    it 'should_not_raise_exception_if_conflicting_type_is_nil_for_name' do
      assert_nothing_raised { machine.state nil }
    end
  end

  context 'WithStatesWithCustomValues' do
    let(:machine) { StateMachines::Machine.new(klass) }
    let(:state) { machine.state :parked, value: 1 }

    let(:object) do
      object = klass.new
      object.state = 1
      object
    end

    it 'should_use_custom_value' do
      assert_equal 1, state.value
    end

    it 'should_allow_lookup_by_custom_value' do
      assert_equal state, machine.states[1, :value]
    end
  end

  context 'WithStatesWithCustomHumanNames' do
    let!(:machine) { StateMachines::Machine.new(klass) }
    let!(:state) { machine.state :parked, human_name: 'stopped' }


    it 'should_use_custom_human_name' do
      assert_equal 'stopped', state.human_name
    end

    it 'should_allow_human_state_name_lookup' do
      assert_equal 'stopped', klass.human_state_name(:parked)
    end
  end

  context 'WithStatesWithRuntimeDependencies' do
    before(:each) do
      machine.state :parked
    end

    it 'should_not_evaluate_value_during_definition' do
      assert_nothing_raised { machine.state :parked, value: lambda { fail ArgumentError } }
    end

    it 'should_not_evaluate_if_not_initial_state' do
      machine.state :parked, value: lambda { fail ArgumentError }
      assert_nothing_raised { klass.new }
    end
  end

  context 'WithStateWithMatchers' do
    let!(:state) { machine.state :parked, if: lambda { |value| value } }
    before(:each) do
      object.state = 1
    end

    it 'should_use_custom_matcher' do
      assert_not_nil state.matcher
      assert state.matches?(1)
      assert !state.matches?(nil)
    end
  end

  context 'WithCachedState' do

    let!(:machine) { StateMachines::Machine.new(klass, initial: :parked) }
    let!(:state) { machine.state :parked, value: lambda { Object.new }, cache: true }


    it 'should_use_evaluated_value' do
      assert_instance_of Object, object.state
    end

    it 'use_same_value_across_multiple_objects' do
      assert_equal object.state, klass.new.state
    end
  end

  context 'WithStatesWithBehaviors' do

    let(:machine) { StateMachines::Machine.new(klass) }
    before(:each) do
      @parked, @idling = machine.state :parked, :idling do
        def speed
          0
        end
      end
    end

    it 'should_define_behaviors_for_each_state' do
      assert_not_nil @parked.context_methods[:speed]
      assert_not_nil @idling.context_methods[:speed]
    end

    it 'should_define_different_behaviors_for_each_state' do
      assert_not_equal @parked.context_methods[:speed], @idling.context_methods[:speed]
    end
  end

  context 'WithExistingState' do

    let!(:state) { machine.state :parked }
    let!(:same_state) { machine.state :parked, value: 1 }

    it 'should_not_create_a_new_state' do
      assert_same state, same_state
    end

    it 'should_update_attributes' do
      assert_equal 1, state.value
    end

    it 'should_no_longer_be_able_to_look_up_state_by_original_value' do
      assert_nil machine.states['parked', :value]
    end

    it 'should_be_able_to_look_up_state_by_new_value' do
      assert_equal state, machine.states[1, :value]
    end
  end

  context 'WithStateMatchers' do


    it 'should_empty_array_for_all_matcher' do
      assert_equal [], machine.state(StateMachines::AllMatcher.instance)
    end

    it 'should_return_referenced_states_for_blacklist_matcher' do
      assert_instance_of StateMachines::State, machine.state(StateMachines::BlacklistMatcher.new([:parked]))
    end

    it 'should_not_allow_configurations' do
      assert_raise(ArgumentError) { machine.state(StateMachines::BlacklistMatcher.new([:parked]), human_name: 'Parked') }
      # FIXME
      #assert_equal 'Cannot configure states when using matchers (using {:human_name=>"Parked"})', exception.message
    end

    it 'should_track_referenced_states' do
      machine.state(StateMachines::BlacklistMatcher.new([:parked]))
      assert_equal [nil, :parked], machine.states.map { |state| state.name }
    end

    it 'should_eval_context_for_matching_states' do
      contexts_run = []
      machine.event(StateMachines::BlacklistMatcher.new([:parked])) { contexts_run << name }

      machine.event :parked
      assert_equal [], contexts_run

      machine.event :idling
      assert_equal [:idling], contexts_run

      machine.event :first_gear, :second_gear
      assert_equal [:idling, :first_gear, :second_gear], contexts_run
    end
  end

  context 'WithOtherStates' do
    let(:machine) { StateMachines::Machine.new(klass, initial: :parked) }
    before(:each) do
      @parked, @idling = machine.other_states(:parked, :idling)
    end

    it 'should_include_other_states_in_known_states ' do
      assert_equal [@parked, @idling], machine.states.to_a
    end

    it 'should_use_default_value ' do
      assert_equal 'idling', @idling.value
    end

    it 'should_not_create_matcher ' do
      assert_nil @idling.matcher
    end
  end

  context ' WithEvents ' do

    it 'should_return_the_created_event ' do
      assert_instance_of StateMachines::Event, machine.event(:ignite)
    end

    it 'should_create_event_with_given_name ' do
      event = machine.event(:ignite) {}
      assert_equal :ignite, event.name
    end

    it 'should_evaluate_block_within_event_context ' do
      responded = false
      machine.event :ignite do
        responded = respond_to?(:transition)
      end

      assert responded
    end

    it 'should_be_aliased_as_on ' do
      event = machine.on(:ignite) {}
      assert_equal :ignite, event.name
    end

    it 'should_have_events ' do
      event = machine.event(:ignite)
      assert_equal [event], machine.events.to_a
    end

    it 'should_allow_human_state_name_lookup ' do
      machine.event(:ignite)
      assert_equal 'ignite', klass.human_state_event_name(:ignite)
    end

    it 'should_raise_exception_on_invalid_human_state_event_name_lookup ' do
      machine
      assert_raise(IndexError) { klass.human_state_event_name(:invalid) }
      # FIXME
      #assert_equal ' : invalid is an invalid name ', exception.message
    end

    it 'should_raise_exception_if_conflicting_type_used_for_name ' do
      machine.event :park
      assert_raise(ArgumentError) { machine.event 'ignite' }
      # FIXME
      #assert_equal ' "ignite" event defined as String, :park defined as Symbol; all events must be consistent ', exception.message
    end
  end

  context ' WithExistingEvent ' do
    let!(:machine) { StateMachines::Machine.new(Class.new) }
    let!(:event) { machine.event(:ignite) }
    let!(:same_event) { machine.event(:ignite) }

    it 'should_not_create_new_event ' do
      expect(event).to equal(same_event)
    end

    it 'should_allow_accessing_event_without_block ' do
      expect(machine.event(:ignite)).to eq(event)
    end
  end

  context ' WithEventsWithCustomHumanNames ' do
    let!(:event) { machine.event(:ignite, human_name: 'start ') }

    it 'should_use_custom_human_name ' do
      assert_equal 'start ', event.human_name
    end

    it 'should_allow_human_state_name_lookup ' do
      assert_equal 'start ', klass.human_state_event_name(:ignite)
    end
  end

  context ' WithEventMatchers ' do


    it 'should_empty_array_for_all_matcher ' do
      assert_equal [], machine.event(StateMachines::AllMatcher.instance)
    end

    it 'should_return_referenced_events_for_blacklist_matcher ' do
      assert_instance_of StateMachines::Event, machine.event(StateMachines::BlacklistMatcher.new([:park]))
    end

    it 'should_not_allow_configurations ' do
      assert_raise(ArgumentError) { machine.event(StateMachines::BlacklistMatcher.new([:park]), human_name: ' Park ') }
      # FIXME
      #assert_equal ' Cannot configure events when using matchers (using { :human_name => "Park" }) ', exception.message
    end

    it 'should_track_referenced_events ' do
      machine.event(StateMachines::BlacklistMatcher.new([:park]))
      assert_equal [:park], machine.events.map { |event| event.name }
    end

    it 'should_eval_context_for_matching_events ' do
      contexts_run = []
      machine.event(StateMachines::BlacklistMatcher.new([:park])) { contexts_run << name }

      machine.event :park
      assert_equal [], contexts_run

      machine.event :ignite
      assert_equal [:ignite], contexts_run

      machine.event :shift_up, :shift_down
      assert_equal [:ignite, :shift_up, :shift_down], contexts_run
    end
  end

  context 'WithEventsWithTransitions' do

    let!(:machine) { StateMachines::Machine.new(klass, initial: :parked) }
    let!(:event) do
      machine.event(:ignite) do
        transition parked: :idling
        transition stalled: :idling
      end
    end

    it 'should_have_events ' do
      assert_equal [event], machine.events.to_a
    end

    it 'should_track_states_defined_in_event_transitions ' do
      assert_equal [:parked, :idling, :stalled], machine.states.map { |state| state.name }
    end

    it 'should_not_duplicate_states_defined_in_multiple_event_transitions ' do
      machine.event :park do
        transition idling: :parked
      end

      assert_equal [:parked, :idling, :stalled], machine.states.map { |state| state.name }
    end

    it 'should_track_state_from_new_events ' do
      machine.event :shift_up do
        transition idling: :first_gear
      end

      assert_equal [:parked, :idling, :stalled, :first_gear], machine.states.map { |state| state.name }
    end
  end

  context ' WithMultipleEvents ' do

    let(:machine) { StateMachines::Machine.new(klass, initial: :parked) }
    before(:each) do
      @park, @shift_down = machine.event(:park, :shift_down) do
        transition first_gear: :parked
      end
    end

    it 'should_have_events ' do
      assert_equal [@park, @shift_down], machine.events.to_a
    end

    it 'should_define_transitions_for_each_event ' do
      [@park, @shift_down].each { |event| assert_equal 1, event.branches.size }
    end

    it 'should_transition_the_same_for_each_event ' do
      object = klass.new
      object.state = 'first_gear'
      object.park
      assert_equal 'parked', object.state

      object = klass.new
      object.state = 'first_gear'
      object.shift_down
      assert_equal 'parked', object.state
    end
  end

  context ' WithTransitions ' do
    let!(:machine) { StateMachines::Machine.new(klass, initial: :parked) }

    it 'should_require_on_event ' do
      assert_raise(ArgumentError) { machine.transition(parked: :idling) }
      # FIXME
      #assert_equal ' Must specify : on event ', exception.message
    end

    it 'should_not_allow_except_on_option ' do
      assert_raise(ArgumentError) { machine.transition(except_on: :ignite, on: :ignite) }
      # FIXME
      #assert_equal ' Invalid key(s) : except_on ', exception.message
    end

    it 'should_allow_transitioning_without_a_to_state ' do
      assert_nothing_raised { machine.transition(from: :parked, on: :ignite) }
    end

    it 'should_allow_transitioning_without_a_from_state ' do
      assert_nothing_raised { machine.transition(to: :idling, on: :ignite) }
    end

    it 'should_allow_except_from_option ' do
      assert_nothing_raised { machine.transition(except_from: :idling, on: :ignite) }
    end

    it 'should_allow_except_to_option ' do
      assert_nothing_raised { machine.transition(except_to: :parked, on: :ignite) }
    end

    it 'should_allow_implicit_options ' do
      branch = machine.transition(first_gear: :second_gear, on: :shift_up)
      assert_instance_of StateMachines::Branch, branch

      state_requirements = branch.state_requirements
      assert_equal 1, state_requirements.length

      assert_instance_of StateMachines::WhitelistMatcher, state_requirements[0][:from]
      assert_equal [:first_gear], state_requirements[0][:from].values
      assert_instance_of StateMachines::WhitelistMatcher, state_requirements[0][:to]
      assert_equal [:second_gear], state_requirements[0][:to].values
      assert_instance_of StateMachines::WhitelistMatcher, branch.event_requirement
      assert_equal [:shift_up], branch.event_requirement.values
    end

    it 'should_allow_multiple_implicit_options ' do
      branch = machine.transition(first_gear: :second_gear, second_gear: :third_gear, on: :shift_up)

      state_requirements = branch.state_requirements
      assert_equal 2, state_requirements.length
    end

    it 'should_allow_verbose_options ' do
      branch = machine.transition(from: :parked, to: :idling, on: :ignite)
      assert_instance_of StateMachines::Branch, branch
    end

    it 'should_include_all_transition_states_in_machine_states ' do
      machine.transition(parked: :idling, on: :ignite)

      assert_equal [:parked, :idling], machine.states.map { |state| state.name }
    end

    it 'should_include_all_transition_events_in_machine_events ' do
      machine.transition(parked: :idling, on: :ignite)

      assert_equal [:ignite], machine.events.map { |event| event.name }
    end

    it 'should_allow_multiple_events ' do
      branches = machine.transition(parked: :ignite, on: [:ignite, :shift_up])

      assert_equal 2, branches.length
      assert_equal [:ignite, :shift_up], machine.events.map { |event| event.name }
    end

    it 'should_not_modify_options ' do
      options = {parked: :idling, on: :ignite}
      machine.transition(options)

      assert_equal options, parked: :idling, on: :ignite
    end
  end

  context ' WithTransitionCallbacks ' do

    let(:klass) do
      Class.new do
        attr_accessor :callbacks
      end
    end

    let!(:machine) { StateMachines::Machine.new(klass, initial: :parked) }
    let!(:event) do
      machine.event :ignite do
        transition parked: :idling
      end
    end
    before(:each) do
      object.callbacks = []
    end

    it 'should_not_raise_exception_if_implicit_option_specified ' do
      assert_nothing_raised { machine.before_transition invalid: :valid, do: lambda {} }
    end

    it 'should_raise_exception_if_method_not_specified ' do
      assert_raise(ArgumentError) { machine.before_transition to: :idling }
      # FIXME
      #assert_equal ' Method(s) for callback must be specified ', exception.message
    end

    it 'should_invoke_callbacks_during_transition' do
      machine.before_transition lambda { |object| object.callbacks << 'before' }
      machine.after_transition lambda { |object| object.callbacks << 'after' }
      machine.around_transition lambda { |object, transition, block| object.callbacks << 'before_around'; block.call; object.callbacks << 'after_around' }

      event.fire(object)
      assert_equal %w(before before_around after_around after), object.callbacks
    end

    it 'should_allow_multiple_callbacks ' do
      machine.before_transition lambda { |object| object.callbacks << 'before1' }, lambda { |object| object.callbacks << 'before2' }
      machine.after_transition lambda { |object| object.callbacks << 'after1' }, lambda { |object| object.callbacks << 'after2' }
      machine.around_transition(
          lambda { |object, transition, block| object.callbacks << 'before_around1'; block.call; object.callbacks << 'after_around1' },
          lambda { |object, transition, block| object.callbacks << 'before_around2'; block.call; object.callbacks << 'after_around2' }
      )

      event.fire(object)
      assert_equal %w(before1 before2 before_around1 before_around2 after_around2 after_around1 after1 after2), object.callbacks
    end

    it 'should_allow_multiple_callbacks_with_requirements ' do
      machine.before_transition lambda { |object| object.callbacks << 'before_parked1' }, lambda { |object| object.callbacks << 'before_parked2' }, from: :parked
      machine.before_transition lambda { |object| object.callbacks << 'before_idling1' }, lambda { |object| object.callbacks << 'before_idling2' }, from: :idling
      machine.after_transition lambda { |object| object.callbacks << 'after_parked1' }, lambda { |object| object.callbacks << 'after_parked2' }, from: :parked
      machine.after_transition lambda { |object| object.callbacks << 'after_idling1' }, lambda { |object| object.callbacks << 'after_idling2' }, from: :idling
      machine.around_transition(
          lambda { |object, transition, block| object.callbacks << 'before_around_parked1'; block.call; object.callbacks << 'after_around_parked1' },
          lambda { |object, transition, block| object.callbacks << 'before_around_parked2'; block.call; object.callbacks << 'after_around_parked2' },
          from: :parked
      )
      machine.around_transition(
          lambda { |object, transition, block| object.callbacks << 'before_around_idling1'; block.call; object.callbacks << 'after_around_idling1' },
          lambda { |object, transition, block| object.callbacks << 'before_around_idling2'; block.call; object.callbacks << 'after_around_idling2' },
          from: :idling
      )

      event.fire(object)
      assert_equal %w(before_parked1 before_parked2 before_around_parked1 before_around_parked2 after_around_parked2 after_around_parked1 after_parked1 after_parked2), object.callbacks
    end

    it 'should_support_from_requirement ' do
      machine.before_transition from: :parked, do: lambda { |object| object.callbacks << :parked }
      machine.before_transition from: :idling, do: lambda { |object| object.callbacks << :idling }

      event.fire(object)
      assert_equal [:parked], object.callbacks
    end

    it 'should_support_except_from_requirement ' do
      machine.before_transition except_from: :parked, do: lambda { |object| object.callbacks << :parked }
      machine.before_transition except_from: :idling, do: lambda { |object| object.callbacks << :idling }

      event.fire(object)
      assert_equal [:idling], object.callbacks
    end

    it 'should_support_to_requirement ' do
      machine.before_transition to: :parked, do: lambda { |object| object.callbacks << :parked }
      machine.before_transition to: :idling, do: lambda { |object| object.callbacks << :idling }

      event.fire(object)
      assert_equal [:idling], object.callbacks
    end

    it 'should_support_except_to_requirement ' do
      machine.before_transition except_to: :parked, do: lambda { |object| object.callbacks << :parked }
      machine.before_transition except_to: :idling, do: lambda { |object| object.callbacks << :idling }

      event.fire(object)
      assert_equal [:parked], object.callbacks
    end

    it 'should_support_on_requirement ' do
      machine.before_transition on: :park, do: lambda { |object| object.callbacks << :park }
      machine.before_transition on: :ignite, do: lambda { |object| object.callbacks << :ignite }

      event.fire(object)
      assert_equal [:ignite], object.callbacks
    end

    it 'should_support_except_on_requirement ' do
      machine.before_transition except_on: :park, do: lambda { |object| object.callbacks << :park }
      machine.before_transition except_on: :ignite, do: lambda { |object| object.callbacks << :ignite }

      event.fire(object)
      assert_equal [:park], object.callbacks
    end

    it 'should_support_implicit_requirement ' do
      machine.before_transition parked: :idling, do: lambda { |object| object.callbacks << :parked }
      machine.before_transition idling: :parked, do: lambda { |object| object.callbacks << :idling }

      event.fire(object)
      assert_equal [:parked], object.callbacks
    end

    it 'should_track_states_defined_in_transition_callbacks ' do
      machine.before_transition parked: :idling, do: lambda {}
      machine.after_transition first_gear: :second_gear, do: lambda {}
      machine.around_transition third_gear: :fourth_gear, do: lambda {}

      assert_equal [:parked, :idling, :first_gear, :second_gear, :third_gear, :fourth_gear], machine.states.map { |state| state.name }
    end

    it 'should_not_duplicate_states_defined_in_multiple_event_transitions ' do
      machine.before_transition parked: :idling, do: lambda {}
      machine.after_transition first_gear: :second_gear, do: lambda {}
      machine.after_transition parked: :idling, do: lambda {}
      machine.around_transition parked: :idling, do: lambda {}

      assert_equal [:parked, :idling, :first_gear, :second_gear], machine.states.map { |state| state.name }
    end

    it 'should_define_predicates_for_each_state ' do
      [:parked?, :idling?].each { |predicate| assert object.respond_to?(predicate) }
    end
  end

  context ' WithFailureCallbacks ' do

    let!(:klass) do
      Class.new do
        attr_accessor :callbacks
      end
    end

    let!(:machine) { StateMachines::Machine.new(klass, initial: :parked) }
    let!(:event) { machine.event :ignite }

    before(:each) do
      object.callbacks = []
    end

    it 'should_raise_exception_if_implicit_option_specified ' do
      assert_raise(ArgumentError) { machine.after_failure invalid: :valid, do: lambda {} }
      # FIXME
      #assert_equal 'Invalid key(s) : invalid ', exception.message
    end

    it 'should_raise_exception_if_method_not_specified ' do
      assert_raise(ArgumentError) { machine.after_failure on: :ignite }
      # FIXME
      #assert_equal 'Method(s) for callback must be specified ', exception.message
    end

    it 'should_invoke_callbacks_during_failed_transition' do
      machine.after_failure lambda { |object| object.callbacks << 'failure' }

      event.fire(object)
      assert_equal %w(failure), object.callbacks
    end

    it 'should_allow_multiple_callbacks ' do
      machine.after_failure lambda { |object| object.callbacks << 'failure1' }, lambda { |object| object.callbacks << 'failure2' }

      event.fire(object)
      assert_equal %w(failure1 failure2), object.callbacks
    end

    it 'should_allow_multiple_callbacks_with_requirements ' do
      machine.after_failure lambda { |object| object.callbacks << 'failure_ignite1' }, lambda { |object| object.callbacks << 'failure_ignite2' }, on: :ignite
      machine.after_failure lambda { |object| object.callbacks << 'failure_park1' }, lambda { |object| object.callbacks << 'failure_park2' }, on: :park

      event.fire(object)
      assert_equal %w(failure_ignite1 failure_ignite2), object.callbacks
    end
  end

  context ' WithPaths ' do
    before(:each) do
      machine.event :ignite do
        transition parked: :idling
      end
      machine.event :shift_up do
        transition first_gear: :second_gear
      end

      object.state = 'parked'
    end

    it 'should_have_paths ' do
      assert_equal [[StateMachines::Transition.new(object, machine, :ignite, :parked, :idling)]], machine.paths_for(object)
    end

    it 'should_allow_requirement_configuration ' do
      assert_equal [[StateMachines::Transition.new(object, machine, :shift_up, :first_gear, :second_gear)]], machine.paths_for(object, from: :first_gear)
    end
  end

  context ' WithOwnerSubclass ' do
    before(:each) do
      machine
    end
    let(:subclass) { Class.new(klass) }

    it 'should_have_a_different_collection_of_state_machines ' do
      assert_not_same klass.state_machines, subclass.state_machines
    end

    it 'should_have_the_same_attribute_associated_state_machines ' do
      assert_equal klass.state_machines, subclass.state_machines
    end
  end

  context ' WithExistingMachinesOnOwnerClass ' do

    let!(:machine) { StateMachines::Machine.new(klass, initial: :parked) }
    let!(:second_machine) { StateMachines::Machine.new(klass, :status, initial: :idling) }


    it 'should_track_each_state_machine ' do
      expected = {state: machine, status: second_machine}
      assert_equal expected, klass.state_machines
    end

    it 'should_initialize_state_for_both_machines ' do
      assert_equal 'parked', object.state
      assert_equal 'idling', object.status
    end
  end

  context ' WithExistingMachinesWithSameAttributesOnOwnerClass ' do
    let!(:machine) { StateMachines::Machine.new(klass, initial: :parked) }
    let!(:second_machine) { StateMachines::Machine.new(klass, :public_state, initial: :idling, attribute: :state) }
    let!(:object) { klass.new }

    it 'should_track_each_state_machine ' do
      expected = {state: machine, public_state: second_machine}
      assert_equal expected, klass.state_machines
    end

    it 'should_write_to_state_only_once ' do
      klass.class_eval do
        attr_reader :write_count

        def state=(value)
          @write_count ||= 0
          @write_count += 1
        end
      end
      object = klass.new

      assert_equal 1, object.write_count
    end

    it 'should_initialize_based_on_first_machine ' do
      assert_equal 'parked', object.state
    end

    it 'should_not_allow_second_machine_to_initialize_state ' do
      object.state = nil
      second_machine.initialize_state(object)
      assert_nil object.state
    end

    it 'should_allow_transitions_on_both_machines ' do
      machine.event :ignite do
        transition parked: :idling
      end

      second_machine.event :park do
        transition idling: :parked
      end

      object.ignite
      assert_equal 'idling', object.state

      object.park
      assert_equal 'parked', object.state
    end

    it 'should_copy_new_states_to_sibling_machines ' do
      first_gear= machine.state :first_gear
      assert_equal first_gear, second_machine.state(:first_gear)

      second_gear = second_machine.state :second_gear
      assert_equal second_gear, machine.state(:second_gear)
    end

    it 'should_copy_all_existing_states_to_new_machines ' do
      third_machine = StateMachines::Machine.new(klass, :protected_state, attribute: :state)

      assert_equal machine.state(:parked), third_machine.state(:parked)
      assert_equal machine.state(:idling), third_machine.state(:idling)
    end
  end

  context ' WithExistingMachinesWithSameAttributesOnOwnerSubclass ' do
    let!(:machine) { StateMachines::Machine.new(klass, initial: :parked) }
    let!(:second_machine) { StateMachines::Machine.new(klass, :public_state, initial: :idling, attribute: :state) }
    let(:subclass) { Class.new(klass) }
    let(:object) { subclass.new }

    it 'should_not_copy_sibling_machines_to_subclass_after_initialization ' do
      subclass.state_machine(:state) {}
      assert_equal klass.state_machine(:public_state), subclass.state_machine(:public_state)
    end

    it 'should_copy_sibling_machines_to_subclass_after_new_state ' do
      subclass_machine = subclass.state_machine(:state) {}
      subclass_machine.state :first_gear
      assert_not_equal klass.state_machine(:public_state), subclass.state_machine(:public_state)
    end

    it 'should_copy_new_states_to_sibling_machines ' do
      subclass_machine = subclass.state_machine(:state) {}
      first_gear= subclass_machine.state :first_gear

      second_subclass_machine = subclass.state_machine(:public_state)
      assert_equal first_gear, second_subclass_machine.state(:first_gear)
    end
  end

  context ' WithNamespace ' do
    let!(:machine) do
      StateMachines::Machine.new(klass, namespace: 'alarm', initial: :active) do
        event :enable do
          transition off: :active
        end

        event :disable do
          transition active: :off
        end
      end
    end

    it 'should_namespace_state_predicates ' do
      [:alarm_active?, :alarm_off?].each do |name|
        assert object.respond_to?(name)
      end
    end

    it 'should_namespace_event_checks ' do
      [:can_enable_alarm?, :can_disable_alarm?].each do |name|
        assert object.respond_to?(name)
      end
    end

    it 'should_namespace_event_transition_readers ' do
      [:enable_alarm_transition, :disable_alarm_transition].each do |name|
        assert object.respond_to?(name)
      end
    end

    it 'should_namespace_events ' do
      [:enable_alarm, :disable_alarm].each do |name|
        assert object.respond_to?(name)
      end
    end

    it 'should_namespace_bang_events ' do
      [:enable_alarm!, :disable_alarm!].each do |name|
        assert object.respond_to?(name)
      end
    end
  end

  context ' WithCustomAttribute ' do

    let!(:machine) do
      StateMachines::Integrations.const_set('Custom', Module.new do
        include StateMachines::Integrations::Base

        @defaults = {action: :save, use_transactions: false}

        def create_with_scope(name)
          -> {}
        end

        def create_without_scope(name)
          -> {}
        end
      end)

      StateMachines::Machine.new(klass, :state, attribute: :state_id, initial: :active, integration: :custom) do
        event :ignite do
          transition parked: :idling
        end
      end
    end
    let(:object) { klass.new }

    it 'should_define_a_reader_attribute_for_the_attribute ' do
      assert object.respond_to?(:state_id)
    end

    it 'should_define_a_writer_attribute_for_the_attribute ' do
      assert object.respond_to?(:state_id=)
    end

    it 'should_define_a_predicate_for_the_attribute ' do
      assert object.respond_to?(:state?)
    end

    it 'should_define_a_name_reader_for_the_attribute ' do
      assert object.respond_to?(:state_name)
    end

    it 'should_define_a_human_name_reader_for_the_attribute ' do
      assert object.respond_to?(:state_name)
    end

    it 'should_define_an_event_reader_for_the_attribute ' do
      assert object.respond_to?(:state_events)
    end

    it 'should_define_a_transition_reader_for_the_attribute ' do
      assert object.respond_to?(:state_transitions)
    end

    it 'should_define_a_path_reader_for_the_attribute ' do
      assert object.respond_to?(:state_paths)
    end

    it 'should_define_an_event_runner_for_the_attribute ' do
      assert object.respond_to?(:fire_state_event)
    end

    it 'should_define_a_human_attribute_name_reader ' do
      assert klass.respond_to?(:human_state_name)
    end

    it 'should_define_a_human_event_name_reader ' do
      assert klass.respond_to?(:human_state_event_name)
    end

    it 'should_define_singular_with_scope ' do
      assert klass.respond_to?(:with_state)
    end

    it 'should_define_singular_without_scope ' do
      assert klass.respond_to?(:without_state)
    end

    it 'should_define_plural_with_scope ' do
      assert klass.respond_to?(:with_states)
    end

    it 'should_define_plural_without_scope ' do
      assert klass.respond_to?(:without_states)
    end

    it 'should_define_state_machines_reader ' do
      expected = {state: machine}
      assert_equal expected, klass.state_machines
    end

    after(:each) do
      StateMachines::Integrations.send(:remove_const, 'Custom')
      StateMachines::Integrations.send(:reset)
    end
  end

  context ' FinderWithoutExistingMachine ' do
    let(:machine) { StateMachines::Machine.find_or_create(klass) }

    it 'should_accept_a_block ' do
      called = false
      StateMachines::Machine.find_or_create(Class.new) do
        called = respond_to?(:event)
      end

      assert called
    end

    it 'should_create_a_new_machine ' do
      assert_not_nil machine
    end

    it 'should_use_default_state ' do
      assert_equal :state, machine.attribute
    end
  end

  context ' FinderWithExistingOnSameClass ' do

    let!(:existing_machine) { StateMachines::Machine.new(klass) }
    let!(:machine) { StateMachines::Machine.find_or_create(klass) }

    it 'should_accept_a_block ' do
      called = false
      StateMachines::Machine.find_or_create(klass) do
        called = respond_to?(:event)
      end

      assert called
    end

    it 'should_not_create_a_new_machine ' do
      assert_same machine, existing_machine
    end
  end

  context ' FinderWithExistingMachineOnSuperclass ' do

    before(:each) do
      integration = Module.new do
        include StateMachines::Integrations::Base

        def self.matches?(klass)
          false
        end
      end
      StateMachines::Integrations.const_set('Custom', integration)

      @base_class = Class.new
      @base_machine = StateMachines::Machine.new(@base_class, :status, :action => :save, :integration => :custom)
      @base_machine.event(:ignite) {}
      @base_machine.before_transition(lambda {})
      @base_machine.after_transition(lambda {})
      @base_machine.around_transition(lambda {})

      @klass = Class.new(@base_class)
      @machine = StateMachines::Machine.find_or_create(@klass, :status) {}
    end


    it 'should_accept_a_block' do
      called = false
      StateMachines::Machine.find_or_create(Class.new(@base_class)) do
        called = respond_to?(:event)
      end

      assert called
    end

    it 'should_not_create_a_new_machine_if_no_block_or_options' do
      machine = StateMachines::Machine.find_or_create(Class.new(@base_class), :status)

      assert_same machine, @base_machine
    end

    it 'should_create_a_new_machine_if_given_options' do
      machine = StateMachines::Machine.find_or_create(@klass, :status, :initial => :parked)

      assert_not_nil machine
      assert_not_same machine, @base_machine
    end

    it 'should_create_a_new_machine_if_given_block' do
      assert_not_nil @machine
      assert_not_same @machine, @base_machine
    end

    it 'should_copy_the_base_attribute' do
      assert_equal :status, @machine.attribute
    end

    it 'should_copy_the_base_configuration' do
      assert_equal :save, @machine.action
    end

    it 'should_copy_events' do
      # Can't assert equal arrays since their machines change
      assert_equal 1, @machine.events.length
    end

    it 'should_copy_before_callbacks' do
      assert_equal @base_machine.callbacks[:before], @machine.callbacks[:before]
    end

    it 'should_copy_after_transitions' do
      assert_equal @base_machine.callbacks[:after], @machine.callbacks[:after]
    end

    it 'should_use_the_same_integration' do
      assert((class << @machine; ancestors; end).include?(StateMachines::Integrations::Custom))
    end

    after(:each) do
      StateMachines::Integrations.send(:remove_const, 'Custom')
      StateMachines::Integrations.send(:reset)
    end
  end

  context 'FinderCustomOptions' do
    let!(:machine) { StateMachines::Machine.find_or_create(klass, :status, initial: :parked) }

    it 'should_use_custom_attribute' do
      assert_equal :status, machine.attribute
    end

    it 'should_set_custom_initial_state' do
      assert_equal :parked, machine.initial_state(object).name
    end
  end

end
