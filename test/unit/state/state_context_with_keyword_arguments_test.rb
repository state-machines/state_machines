# frozen_string_literal: true

require 'test_helper'

class StateContextWithKeywordArgumentsTest < StateMachinesTest
  def setup
    base = Class.new do
      def greet(who:, loud: false, &block)
        [:base, who, loud, block&.call]
      end
    end
    @klass = Class.new(base) do
      state_machine(initial: :parked) do
        event(:ignite) { transition parked: :idling }

        state :parked do
          def greet(who:, loud: false, &block)
            [:parked, who, loud, block&.call]
          end

          def store(options)
            options
          end
        end
      end
    end
    @object = @klass.new
  end

  def test_should_forward_keywords_and_the_block
    assert_equal [:parked, 'x', true, 1], @object.greet(who: 'x', loud: true) { 1 }
  end

  def test_should_forward_them_to_super_outside_the_state
    @object.ignite

    assert_equal [:base, 'x', false, 2], @object.greet(who: 'x') { 2 }
  end

  def test_should_require_missing_keywords
    assert_raises(ArgumentError) { @object.greet }
  end

  def test_should_keep_a_positional_hash_positional
    assert_equal({ a: 1 }, @object.store({ a: 1 }))
  end
end
