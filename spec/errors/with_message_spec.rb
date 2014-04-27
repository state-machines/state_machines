require 'spec_helper'

describe 'ErrorWithMessage' do
  let(:klass) { Class.new }
  let(:machine) { StateMachines::Machine.new(klass) }
  let(:collection) { StateMachines::NodeCollection.new(machine) }
  it 'should_raise_exception_if_invalid_option_specified' do
    expect { StateMachines::NodeCollection.new(machine, invalid: true) }.to raise_error(ArgumentError)
    # assert_equal 'Invalid key(s): invalid', exception.message
  end

  it 'should_raise_exception_on_lookup_if_invalid_index_specified' do
    expect { collection[:something, :invalid] }.to raise_error(ArgumentError)
    # assert_equal 'Invalid index: :invalid', exception.message
  end

  it 'should raise exception on fetch if invalid index specified' do
    expect { collection[:something, :invalid] }.to raise_error(ArgumentError)
    # assert_equal 'Invalid index: :invalid', exception.message
  end
end

# class ErrorWithMessageTest < Test::Unit::TestCase
#
#   it 'should_raise_exception_if_invalid_option_specified
#     exception = assert_raise(ArgumentError) { StateMachines::NodeCollection.new(@machine, :invalid => true) }
#     assert_equal 'Invalid key(s): invalid', exception.message
#   end
#
#   it 'should_raise_exception_on_lookup_if_invalid_index_specified
#     exception = assert_raise(ArgumentError) { @collection[:something, :invalid] }
#     assert_equal 'Invalid index: :invalid', exception.message
#   end
#
#   it 'should_raise_exception_on_fetch_if_invalid_index_specified
#     exception = assert_raise(ArgumentError) { @collection.fetch(:something, :invalid) }
#     assert_equal 'Invalid index: :invalid', exception.message
#   end
# end
