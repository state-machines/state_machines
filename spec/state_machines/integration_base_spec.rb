require 'spec_helper'

describe StateMachines::Integrations::Base do
  it { should respond_to(:name) }
  it { should respond_to(:integration_name) }
  it { should respond_to(:available?) }
  it { should respond_to(:matching_ancestors) }
  it { should respond_to(:matches?) }
  it { should respond_to(:matches_ancestors?) }
  it { expect(subject.name).to eq('StateMachines::Integrations::Base') }
  it { expect(subject.integration_name).to eq(:base) }
end