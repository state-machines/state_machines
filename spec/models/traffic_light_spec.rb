require 'spec_helper'

describe TrafficLight do
  let(:light) { TrafficLight.new }
  context 'Stop' do
    before(:each) do
      light.state = 'stop'
    end

    it 'should_use_stop_color' do
      assert_equal 'red', light.color
    end

    it 'should_pass_arguments_through' do
      assert_equal 'RED', light.color(:upcase!)
    end

    it 'should_pass_block_through' do
      color = light.color { |value| value.upcase! }
      assert_equal 'RED', color
    end

    it 'should_use_stop_capture_violations' do
      assert_equal true, light.capture_violations?
    end
  end

 context 'Proceed' do
    before(:each) do
      light.state = 'proceed'
    end

    it 'should_use_proceed_color' do
      assert_equal 'green', light.color
    end

    it 'should_use_proceed_capture_violations' do
      assert_equal false, light.capture_violations?
    end
  end

 context 'Caution' do
    before(:each) do
      light.state = 'caution'
    end

    it 'should_use_caution_color' do
      assert_equal 'yellow', light.color
    end

    it 'should_use_caution_capture_violations' do
      assert_equal true, light.capture_violations?
    end
  end

end
