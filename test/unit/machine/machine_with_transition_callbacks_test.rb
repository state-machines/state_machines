require_relative '../../test_helper'

class MachineWithTransitionCallbacksTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_accessor :callbacks
    end

    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @event = @machine.event :ignite do
      transition parked: :idling
    end

    @object = @klass.new
    @object.callbacks = []
  end

  def test_should_not_raise_exception_if_implicit_option_specified
    @machine.before_transition invalid: :valid, do: -> {}
  end

  def test_should_raise_exception_if_method_not_specified
    exception = assert_raises(ArgumentError) { @machine.before_transition to: :idling }
    assert_equal 'Method(s) for callback must be specified', exception.message
  end

  def test_should_invoke_callbacks_during_transition
    @machine.before_transition lambda { |object| object.callbacks << 'before' }
    @machine.after_transition lambda { |object| object.callbacks << 'after' }
    @machine.around_transition lambda { |object, _transition, block| object.callbacks << 'before_around'; block.call; object.callbacks << 'after_around' }

    @event.fire(@object)
    assert_equal %w(before before_around after_around after), @object.callbacks
  end

  def test_should_allow_multiple_callbacks
    @machine.before_transition lambda { |object| object.callbacks << 'before1' }, lambda { |object| object.callbacks << 'before2' }
    @machine.after_transition lambda { |object| object.callbacks << 'after1' }, lambda { |object| object.callbacks << 'after2' }
    @machine.around_transition(
        lambda { |object, _transition, block| object.callbacks << 'before_around1'; block.call; object.callbacks << 'after_around1' },
        lambda { |object, _transition, block| object.callbacks << 'before_around2'; block.call; object.callbacks << 'after_around2' }
    )

    @event.fire(@object)
    assert_equal %w(before1 before2 before_around1 before_around2 after_around2 after_around1 after1 after2), @object.callbacks
  end

  def test_should_allow_multiple_callbacks_with_requirements
    @machine.before_transition lambda { |object| object.callbacks << 'before_parked1' }, lambda { |object| object.callbacks << 'before_parked2' }, from: :parked
    @machine.before_transition lambda { |object| object.callbacks << 'before_idling1' }, lambda { |object| object.callbacks << 'before_idling2' }, from: :idling
    @machine.after_transition lambda { |object| object.callbacks << 'after_parked1' }, lambda { |object| object.callbacks << 'after_parked2' }, from: :parked
    @machine.after_transition lambda { |object| object.callbacks << 'after_idling1' }, lambda { |object| object.callbacks << 'after_idling2' }, from: :idling
    @machine.around_transition(
        lambda { |object, _transition, block| object.callbacks << 'before_around_parked1'; block.call; object.callbacks << 'after_around_parked1' },
        lambda { |object, _transition, block| object.callbacks << 'before_around_parked2'; block.call; object.callbacks << 'after_around_parked2' },
        from: :parked
    )
    @machine.around_transition(
        lambda { |object, _transition, block| object.callbacks << 'before_around_idling1'; block.call; object.callbacks << 'after_around_idling1' },
        lambda { |object, _transition, block| object.callbacks << 'before_around_idling2'; block.call; object.callbacks << 'after_around_idling2' },
        from: :idling
    )

    @event.fire(@object)
    assert_equal %w(before_parked1 before_parked2 before_around_parked1 before_around_parked2 after_around_parked2 after_around_parked1 after_parked1 after_parked2), @object.callbacks
  end

  def test_should_support_from_requirement
    @machine.before_transition from: :parked, do: lambda { |object| object.callbacks << :parked }
    @machine.before_transition from: :idling, do: lambda { |object| object.callbacks << :idling }

    @event.fire(@object)
    assert_equal [:parked], @object.callbacks
  end

  def test_should_support_except_from_requirement
    @machine.before_transition except_from: :parked, do: lambda { |object| object.callbacks << :parked }
    @machine.before_transition except_from: :idling, do: lambda { |object| object.callbacks << :idling }

    @event.fire(@object)
    assert_equal [:idling], @object.callbacks
  end

  def test_should_support_to_requirement
    @machine.before_transition to: :parked, do: lambda { |object| object.callbacks << :parked }
    @machine.before_transition to: :idling, do: lambda { |object| object.callbacks << :idling }

    @event.fire(@object)
    assert_equal [:idling], @object.callbacks
  end

  def test_should_support_except_to_requirement
    @machine.before_transition except_to: :parked, do: lambda { |object| object.callbacks << :parked }
    @machine.before_transition except_to: :idling, do: lambda { |object| object.callbacks << :idling }

    @event.fire(@object)
    assert_equal [:parked], @object.callbacks
  end

  def test_should_support_on_requirement
    @machine.before_transition on: :park, do: lambda { |object| object.callbacks << :park }
    @machine.before_transition on: :ignite, do: lambda { |object| object.callbacks << :ignite }

    @event.fire(@object)
    assert_equal [:ignite], @object.callbacks
  end

  def test_should_support_except_on_requirement
    @machine.before_transition except_on: :park, do: lambda { |object| object.callbacks << :park }
    @machine.before_transition except_on: :ignite, do: lambda { |object| object.callbacks << :ignite }

    @event.fire(@object)
    assert_equal [:park], @object.callbacks
  end

  def test_should_support_implicit_requirement
    @machine.before_transition parked: :idling, do: lambda { |object| object.callbacks << :parked }
    @machine.before_transition idling: :parked, do: lambda { |object| object.callbacks << :idling }

    @event.fire(@object)
    assert_equal [:parked], @object.callbacks
  end

  def test_should_track_states_defined_in_transition_callbacks
    @machine.before_transition parked: :idling, do: lambda {}
    @machine.after_transition first_gear: :second_gear, do: lambda {}
    @machine.around_transition third_gear: :fourth_gear, do: lambda {}

    assert_equal [:parked, :idling, :first_gear, :second_gear, :third_gear, :fourth_gear], @machine.states.map { |state| state.name }
  end

  def test_should_not_duplicate_states_defined_in_multiple_event_transitions
    @machine.before_transition parked: :idling, do: lambda {}
    @machine.after_transition first_gear: :second_gear, do: lambda {}
    @machine.after_transition parked: :idling, do: lambda {}
    @machine.around_transition parked: :idling, do: lambda {}

    assert_equal [:parked, :idling, :first_gear, :second_gear], @machine.states.map { |state| state.name }
  end

  def test_should_define_predicates_for_each_state
    [:parked?, :idling?].each { |predicate| assert @object.respond_to?(predicate) }
  end
end
