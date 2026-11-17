# frozen_string_literal: true

require 'test_helper'

# The method names below are unusual on purpose
# rubocop:disable Naming/MethodName

# Names that are legal Ruby method names but no `def` can spell must work
# where core wraps the user's own methods, and be rejected up front where
# core has to build instance variables from them.
class MachineWithUnusualNamesTest < StateMachinesTest
  def test_should_reject_a_machine_name_that_is_not_an_ivar_name
    error = assert_raises(ArgumentError) { Class.new { state_machine(:'has space', initial: :parked) } }
    assert_equal ':"has space" is not a valid state machine name: it must be usable as an instance variable name (@has space)', error.message
  end

  def test_should_reject_it_with_a_separate_attribute
    assert_raises(ArgumentError) do
      Class.new do
        attr_accessor :status

        state_machine(:'has space', attribute: :status, initial: :parked)
      end
    end
  end

  def test_should_reject_a_predicate_style_machine_name
    assert_raises(ArgumentError) { Class.new { state_machine(:ready?, initial: :parked) } }
  end

  def test_should_reject_an_attribute_core_must_define
    error = assert_raises(ArgumentError) { Class.new { state_machine(:status, attribute: :'a b', initial: :parked) } }
    assert_match(/:"a b" is not a valid state machine attribute/, error.message)
  end

  def test_should_accept_an_attribute_the_owner_defines
    klass = Class.new do
      define_method(:'a b') { @value }
      define_method(:'a b=') { |value| @value = value }

      state_machine(:status, attribute: :'a b', initial: :parked)
    end

    assert_equal 'parked', klass.new.send(:'a b')
  end

  def test_should_accept_a_keyword_machine_name
    klass = Class.new { state_machine(:end, initial: :parked) }

    assert klass.new.end?(:parked)
  end
end

class MachineWithUnusualActionNameTest < StateMachinesTest
  def setup
    base = Class.new do
      attr_reader :saved

      define_method(:'save it') { @saved = true }
    end

    @klass = Class.new(base) do
      state_machine(initial: :parked, action: :'save it') do
        event(:ignite) { transition parked: :idling }
      end
    end
    @object = @klass.new
  end

  def test_should_run_the_event_through_the_action
    @object.state_event = 'ignite'
    @object.send(:'save it')

    assert_equal 'idling', @object.state
    assert @object.saved
  end

  def test_should_fire_the_event_with_the_action
    assert @object.ignite

    assert_equal 'idling', @object.state
    assert @object.saved
  end
end

class MachineWithPrivateActionTest < StateMachinesTest
  def test_should_keep_the_action_private
    base = Class.new do
      private

      def persist(*_args, flush: false)
        @flushed = flush
      end
    end
    klass = Class.new(base) { state_machine(initial: :parked, action: :persist) { event(:ignite) { transition parked: :idling } } }
    object = klass.new

    assert klass.private_method_defined?(:persist)
    assert object.send(:persist, flush: true)
    assert object.instance_variable_get(:@flushed)
  end
end

class StateContextWithUnusualMethodNamesTest < StateMachinesTest
  def setup
    @klass = Class.new do
      state_machine(initial: :parked) do
        event(:ignite) { transition parked: :idling }

        state :parked do
          define_method(:'do it') { :parked_did_it }

          def [](index)
            [:parked, index]
          end

          protected

          def secret
            :parked_secret
          end
        end
      end
    end
    @object = @klass.new
  end

  def test_should_call_a_method_no_def_can_spell
    assert_equal :parked_did_it, @object.send(:'do it')
  end

  def test_should_call_an_operator_method
    assert_equal [:parked, 3], @object[3]
  end

  def test_should_scope_them_to_the_state
    @object.ignite

    assert_raises(StateMachines::InvalidContext) { @object.send(:'do it') }
    assert_raises(StateMachines::InvalidContext) { @object[3] }
  end

  def test_should_keep_a_protected_method_protected
    assert @klass.protected_method_defined?(:secret)
    assert_raises(NoMethodError) { @object.secret }
    assert_equal :parked_secret, @object.send(:secret)
  end
end

class MachineWithProtectedActionTest < StateMachinesTest
  def setup
    base = Class.new do
      protected

      def persist(*)
        :persisted
      end
    end
    @klass = Class.new(base) { state_machine(initial: :parked, action: :persist) { event(:ignite) { transition parked: :idling } } }
  end

  def test_should_keep_the_action_protected
    assert @klass.protected_method_defined?(:persist)
    assert_raises(NoMethodError) { @klass.new.persist }
  end

  def test_should_still_run_events_through_it
    object = @klass.new

    assert object.ignite
    assert_equal 'idling', object.state
  end
end

# rubocop:enable Naming/MethodName
