require 'spec_helper'

describe StateMachines::HelperModule do
  let(:klass) { Class.new }
  let(:machine) { StateMachines::Machine.new(klass) }
  let(:helper_module) { StateMachines::HelperModule.new(machine, :instance) }
  it 'should not have a name' do
    expect(helper_module.name.to_s).to eq('')
  end

  it 'should_provide_human_readable_to_s' do
    expect(helper_module.to_s).to eq("#{klass} :state instance helpers")
  end
end
