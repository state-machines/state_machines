# frozen_string_literal: true

require 'test_helper'

class StateContextWithPrivateMethodTest < StateMachinesTest
  def setup
    @klass = Class.new do
      state_machine(initial: :parked) do
        event(:ignite) { transition parked: :idling }

        state :parked do
          def reveal
            secret
          end

          private

          def secret
            :parked_secret
          end
        end
      end
    end
    @object = @klass.new
  end

  def test_should_keep_it_private
    assert @klass.private_method_defined?(:secret)
    assert_raises(NoMethodError) { @object.secret }
  end

  def test_should_run_it_in_its_state
    assert_equal :parked_secret, @object.send(:secret)
    assert_equal :parked_secret, @object.reveal
  end

  def test_should_not_run_its_state_body_in_another_state
    @object.ignite

    assert_raises(StateMachines::InvalidContext) { @object.send(:secret) }
  end

  def test_should_fall_through_to_an_inherited_method_in_another_state
    klass = Class.new(Class.new { def secret = :inherited }) do
      state_machine(initial: :parked) do
        event(:ignite) { transition parked: :idling }
        state(:parked) { private def secret = :parked_secret }
      end
    end
    object = klass.new
    object.ignite

    assert_equal :inherited, object.send(:secret)
  end
end
