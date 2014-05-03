require 'spec_helper'

describe StateMachines::Integrations do

  it { expect(StateMachines::Integrations).to respond_to(:register) }
  it { expect(StateMachines::Integrations).to respond_to(:integrations) }
  it { expect(StateMachines::Integrations).to respond_to(:match) }
  it { expect(StateMachines::Integrations).to respond_to(:match_ancestors) }
  it { expect(StateMachines::Integrations).to respond_to(:find_by_name) }
  describe '#register' do
    before(:each) do
      StateMachines::Integrations.const_set('Custom', Module.new do
        include StateMachines::Integrations::Base
      end)
    end

    it 'should register integration' do
      expect(StateMachines::Integrations.register(StateMachines::Integrations::Custom)).to be_truthy
    end

    after(:each) do
      StateMachines::Integrations.send(:remove_const, 'Custom')
      StateMachines::Integrations.send(:reset)
    end

  end

  describe '#integrations' do
    before(:each) do
      StateMachines::Integrations.const_set('Custom', Module.new do
        include StateMachines::Integrations::Base
      end)
      StateMachines::Integrations.register(StateMachines::Integrations::Custom)
    end

    it 'should register integration' do
      expect(StateMachines::Integrations.integrations).to include(StateMachines::Integrations::Custom)
    end

    after(:each) do
      StateMachines::Integrations.send(:remove_const, 'Custom')
      StateMachines::Integrations.send(:reset)
    end
  end

  context 'do' do
    before(:all) do
      Object.const_set('CustomIntegration', Module.new do
        include StateMachines::Integrations::Base
        class << self
          def matching_ancestors
            %w(Bar)
          end
        end
      end)
      StateMachines::Integrations.const_set('Hogue', Module.new do
        include StateMachines::Integrations::Base
        class << self
          def matching_ancestors
            %w(Hogue Foo)
          end
        end
      end)
      class Bar
      end
      class Hogue
      end
      class Foo
      end

      StateMachines::Integrations.register(CustomIntegration)
    end

    describe 'StateMachines::Integrations::Hogue' do
      let(:subject) { StateMachines::Integrations::Hogue }
      it { should respond_to(:name) }
      it { should respond_to(:integration_name) }
      it { should respond_to(:available?) }
      it { should respond_to(:matching_ancestors) }
      it { should respond_to(:matches?) }
      it { should respond_to(:matches_ancestors?) }
      it { expect(subject.name).to eq('StateMachines::Integrations::Hogue') }
      it { expect(subject.matching_ancestors).to eq(%w(Hogue Foo)) }
    end

    describe 'CustomIntegration' do
      let(:subject) { CustomIntegration }
      it { should respond_to(:name) }
      it { should respond_to(:integration_name) }
      it { should respond_to(:available?) }
      it { should respond_to(:matching_ancestors) }
      it { should respond_to(:matches?) }
      it { should respond_to(:matches_ancestors?) }
      it { expect(subject.name).to eq('CustomIntegration') }
      it { expect(subject.integration_name).to eq(:custom_integration) }
      it { expect(subject.matching_ancestors).to eq(%w(Bar)) }
    end

    describe '#match' do


      it 'should match correct integration' do

        expect(StateMachines::Integrations.match(Bar)).to eq(CustomIntegration)
        expect(StateMachines::Integrations.match(Hogue)).to eq(StateMachines::Integrations::Hogue)
        expect(StateMachines::Integrations.match(Foo)).to eq(StateMachines::Integrations::Hogue)
      end


    end

    describe '#match_ancestors' do
      it { expect(StateMachines::Integrations.match_ancestors([])).to be_nil }
      it { expect(StateMachines::Integrations.match_ancestors(['Foo'])).to eq(StateMachines::Integrations::Hogue) }
      it { expect(StateMachines::Integrations.match_ancestors(['Hogue'])).to eq(StateMachines::Integrations::Hogue) }
      it { expect(StateMachines::Integrations.match_ancestors(['Foo', 'Hogue'])).to eq(StateMachines::Integrations::Hogue) }
      it { expect(StateMachines::Integrations.match_ancestors(['Bar'])).to eq(CustomIntegration) }
    end

    describe '#find_by_name' do
     pending
    end

    after(:all) do
      Object.send(:remove_const, 'CustomIntegration')
      StateMachines::Integrations.send(:remove_const, 'Hogue')
      StateMachines::Integrations.send(:reset)
    end
  end


end