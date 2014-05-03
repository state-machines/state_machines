context 'Default' do
  before(:each) do
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @state = @machine.state :parked
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'

    @invalid_transition = StateMachines::InvalidTransition.new(@object, @machine, :ignite)
  end

  it 'should_have_an_object' do
    assert_equal @object, @invalid_transition.object
  end

  it 'should_have_a_machine' do
    assert_equal @machine, @invalid_transition.machine
  end

  it 'should_have_an_event' do
    assert_equal :ignite, @invalid_transition.event
  end

  it 'should_have_a_qualified_event' do
    assert_equal :ignite, @invalid_transition.qualified_event
  end

  it 'should_have_a_from_value' do
    assert_equal 'parked', @invalid_transition.from
  end

  it 'should_have_a_from_name' do
    assert_equal :parked, @invalid_transition.from_name
  end

  it 'should_have_a_qualified_from_name' do
    assert_equal :parked, @invalid_transition.qualified_from_name
  end

  it 'should_generate_a_message' do
    assert_equal 'Cannot transition state via :ignite from :parked', @invalid_transition.message
  end
end

context 'WithNamespace' do
  before(:each) do
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, :namespace => 'alarm')
    @state = @machine.state :active
    @machine.event :disable

    @object = @klass.new
    @object.state = 'active'

    @invalid_transition = StateMachines::InvalidTransition.new(@object, @machine, :disable)
  end

  it 'should_have_an_event' do
    assert_equal :disable, @invalid_transition.event
  end

  it 'should_have_a_qualified_event' do
    assert_equal :disable_alarm, @invalid_transition.qualified_event
  end

  it 'should_have_a_from_name' do
    assert_equal :active, @invalid_transition.from_name
  end

  it 'should_have_a_qualified_from_name' do
    assert_equal :alarm_active, @invalid_transition.qualified_from_name
  end
end

context 'WithIntegration' do
  before(:each) do
    StateMachines::Integrations.const_set('Custom', Module.new do
      include StateMachines::Integrations::Base

      def errors_for(object)
        object.errors
      end
    end)

    @klass = Class.new do
      attr_accessor :errors
    end
    @machine = StateMachines::Machine.new(@klass, :integration => :custom)
    @machine.state :parked
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
  end

  it 'should_generate_a_message_without_reasons_if_empty' do
    @object.errors = ''
    invalid_transition = StateMachines::InvalidTransition.new(@object, @machine, :ignite)
    assert_equal 'Cannot transition state via :ignite from :parked', invalid_transition.message
  end

  it 'should_generate_a_message_with_error_reasons_if_errors_found' do
    @object.errors = 'Id is invalid, Name is invalid'
    invalid_transition = StateMachines::InvalidTransition.new(@object, @machine, :ignite)
    assert_equal 'Cannot transition state via :ignite from :parked (Reason(s): Id is invalid, Name is invalid)', invalid_transition.message
  end

  after(:each) do
    StateMachines::Integrations.send(:remove_const, 'Custom')
    StateMachines::Integrations.send(:reset)
  end
end
