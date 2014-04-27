require 'spec_helper'

describe Motorcycle do
  let(:motorcycle) { Motorcycle.new }

  it 'should_be_in_idling_state' do
    assert_equal 'idling', motorcycle.state
  end

  it 'should_allow_park' do
    assert motorcycle.park
  end

  it 'should_not_allow_ignite' do
    assert !motorcycle.ignite
  end

  it 'should_allow_shift_up' do
    assert motorcycle.shift_up
  end

  it 'should_not_allow_shift_down' do
    assert !motorcycle.shift_down
  end

  it 'should_not_allow_crash' do
    assert !motorcycle.crash
  end

  it 'should_not_allow_repair' do
    assert !motorcycle.repair
  end

  it 'should_inherit_decibels_from_superclass' do
    motorcycle.park
    assert_equal 0.0, motorcycle.decibels
  end

  it 'should_use_decibels_defined_in_state' do
    motorcycle.shift_up
    assert_equal 1.0, motorcycle.decibels
  end

end
