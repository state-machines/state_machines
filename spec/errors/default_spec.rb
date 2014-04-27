require 'spec_helper'

describe 'ErrorByDefault' do
  let(:klass) { Class.new }
  let(:machine) { StateMachines::Machine.new(klass) }
  let(:collection) { StateMachines::NodeCollection.new(machine) }
  it '#length' do
    expect(collection.length).to eq(0)
  end

  it  do
    expect(collection.machine).to eq(machine)
  end
end
