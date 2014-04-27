require 'spec_helper'
describe 'StateMachines' do
  context 'ByDefault' do
    before(:each) do
      @klass = Class.new
      @machine = @klass.state_machine
    end

    it 'should_use_state_attribute' do
      assert_equal :state, @machine.attribute
    end
  end

  context '' do
    let(:klass) { Class.new }

    it 'should_allow_state_machines_on_any_class' do
      expect(klass.respond_to?(:state_machine)).to be_truthy
    end

    it 'should_evaluate_block_within_machine_context' do
      responded = false
      klass.state_machine(:state) do
        responded = respond_to?(:event)
      end
      expect(responded).to be_truthy
    end
  end
end
