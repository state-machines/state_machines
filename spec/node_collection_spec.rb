require 'spec_helper'

class Node < Struct.new(:name, :value, :machine)
  def context
    yield
  end
end
describe StateMachines::NodeCollection do
  context 'ByDefault' do
    before(:each) do
      @machine = StateMachines::Machine.new(Class.new)
      @collection = StateMachines::NodeCollection.new(@machine)
    end

    it 'should_not_have_any_nodes' do
      assert_equal 0, @collection.length
    end

    it 'should_have_a_machine' do
      assert_equal @machine, @collection.machine
    end

    it 'should_index_by_name' do
      @collection << object = Node.new(:parked)
      assert_equal object, @collection[:parked]
    end
  end

  context '' do
    before(:each) do
      @machine = StateMachines::Machine.new(Class.new)
      @collection = StateMachines::NodeCollection.new(@machine)
    end

    it 'should_raise_exception_if_invalid_option_specified' do
      assert_raise(ArgumentError) { StateMachines::NodeCollection.new(@machine, :invalid => true) }
      # FIXME
      #assert_equal 'Invalid key(s): invalid', exception.message
    end

    it 'should_raise_exception_on_lookup_if_invalid_index_specified' do
      assert_raise(ArgumentError) { @collection[:something, :invalid] }
      # FIXME
      #assert_equal 'Invalid index: :invalid', exception.message
    end

    it 'should_raise_exception_on_fetch_if_invalid_index_specified' do
      assert_raise(ArgumentError) { @collection.fetch(:something, :invalid) }
      # FIXME
      #assert_equal 'Invalid index: :invalid', exception.message
    end
  end

  context 'AfterBeingCopied' do
    before(:each) do
      machine = StateMachines::Machine.new(Class.new)
      @collection = StateMachines::NodeCollection.new(machine)
      @collection << @parked = Node.new(:parked)

      @contexts_run = contexts_run = []
      @collection.context([:parked]) { contexts_run << :parked }
      @contexts_run.clear

      @copied_collection = @collection.dup
      @copied_collection << @idling = Node.new(:idling)
      @copied_collection.context([:first_gear]) { contexts_run << :first_gear }
    end

    it 'should_not_modify_the_original_list' do
      assert_equal 1, @collection.length
      assert_equal 2, @copied_collection.length
    end

    it 'should_not_modify_the_indices' do
      assert_nil @collection[:idling]
      assert_equal @idling, @copied_collection[:idling]
    end

    it 'should_copy_each_node' do
      assert_not_same @parked, @copied_collection[:parked]
    end

    it 'should_not_run_contexts' do
      assert_equal [], @contexts_run
    end

    it 'should_not_modify_contexts' do
      @collection << Node.new(:first_gear)
      assert_equal [], @contexts_run
    end

    it 'should_copy_contexts' do
      @copied_collection << Node.new(:parked)
      assert !@contexts_run.empty?
    end
  end

  context 'WithoutIndices' do
    before(:each) do
      machine = StateMachines::Machine.new(Class.new)
      @collection = StateMachines::NodeCollection.new(machine, :index => {})
    end

    it 'should_allow_adding_node' do
      @collection << Object.new
      assert_equal 1, @collection.length
    end

    it 'should_not_allow_keys_retrieval' do
      assert_raise(ArgumentError) { @collection.keys }
      # FIXME
      #assert_equal 'No indices configured', exception.message
    end

    it 'should_not_allow_lookup' do
      @collection << Object.new
      assert_raise(ArgumentError) { @collection[0] }
      # FIXME
      # assert_equal 'No indices configured', exception.message
    end

    it 'should_not_allow_fetching' do
      @collection << Object.new
      assert_raise(ArgumentError) { @collection.fetch(0) }
      # FIXME
      #assert_equal 'No indices configured', exception.message
    end
  end

  context 'WithIndices' do
    before(:each) do
      machine = StateMachines::Machine.new(Class.new)
      @collection = StateMachines::NodeCollection.new(machine, :index => [:name, :value])

      @object = Node.new(:parked, 1)
      @collection << @object
    end

    it 'should_use_first_index_by_default_on_key_retrieval' do
      assert_equal [:parked], @collection.keys
    end

    it 'should_allow_customizing_index_for_key_retrieval' do
      assert_equal [1], @collection.keys(:value)
    end

    it 'should_use_first_index_by_default_on_lookup' do
      assert_equal @object, @collection[:parked]
      assert_nil @collection[1]
    end

    it 'should_allow_customizing_index_on_lookup' do
      assert_equal @object, @collection[1, :value]
      assert_nil @collection[:parked, :value]
    end

    it 'should_use_first_index_by_default_on_fetch' do
      assert_equal @object, @collection.fetch(:parked)
      assert_raise(IndexError) { @collection.fetch(1) }
      # FIXME
      #assert_equal '1 is an invalid name', exception.message
    end

    it 'should_allow_customizing_index_on_fetch' do
      assert_equal @object, @collection.fetch(1, :value)
      assert_raise(IndexError) { @collection.fetch(:parked, :value) }
      # FIXME
      #assert_equal ':parked is an invalid value', exception.message
    end
  end

  context 'WithNodes' do
    before(:each) do
      @machine = StateMachines::Machine.new(Class.new)
      @collection = StateMachines::NodeCollection.new(@machine)

      @parked = Node.new(:parked, nil, @machine)
      @idling = Node.new(:idling, nil, @machine)

      @collection << @parked
      @collection << @idling
    end

    it 'should_be_able_to_enumerate' do
      order = []
      @collection.each { |object| order << object }

      assert_equal [@parked, @idling], order
    end

    it 'should_be_able_to_concatenate_multiple_nodes' do
      @first_gear = Node.new(:first_gear, nil, @machine)
      @second_gear = Node.new(:second_gear, nil, @machine)
      @collection.concat([@first_gear, @second_gear])

      order = []
      @collection.each { |object| order << object }
      assert_equal [@parked, @idling, @first_gear, @second_gear], order
    end

    it 'should_be_able_to_access_by_index' do
      assert_equal @parked, @collection.at(0)
      assert_equal @idling, @collection.at(1)
    end

    it 'should_deep_copy_machine_changes' do
      new_machine = StateMachines::Machine.new(Class.new)
      @collection.machine = new_machine

      assert_equal new_machine, @collection.machine
      assert_equal new_machine, @parked.machine
      assert_equal new_machine, @idling.machine
    end
  end

  context 'AfterUpdate' do
    before(:each) do
      machine = StateMachines::Machine.new(Class.new)
      @collection = StateMachines::NodeCollection.new(machine, :index => [:name, :value])

      @parked = Node.new(:parked, 1)
      @idling = Node.new(:idling, 2)

      @collection << @parked << @idling

      @parked.name = :parking
      @parked.value = 0
      @collection.update(@parked)
    end

    it 'should_not_change_the_index' do
      assert_equal @parked, @collection.at(0)
    end

    it 'should_not_duplicate_in_the_collection' do
      assert_equal 2, @collection.length
    end

    it 'should_add_each_indexed_key' do
      assert_equal @parked, @collection[:parking]
      assert_equal @parked, @collection[0, :value]
    end

    it 'should_remove_each_old_indexed_key' do
      assert_nil @collection[:parked]
      assert_nil @collection[1, :value]
    end
  end

  context 'WithStringIndex' do
    before(:each) do
      machine = StateMachines::Machine.new(Class.new)
      @collection = StateMachines::NodeCollection.new(machine, :index => [:name, :value])

      @parked = Node.new(:parked, 1)
      @collection << @parked
    end

    it 'should_index_by_name' do
      assert_equal @parked, @collection[:parked]
    end

    it 'should_index_by_string_name' do
      assert_equal @parked, @collection['parked']
    end
  end

  context 'WithSymbolIndex' do
    before(:each) do
      machine = StateMachines::Machine.new(Class.new)
      @collection = StateMachines::NodeCollection.new(machine, :index => [:name, :value])

      @parked = Node.new('parked', 1)
      @collection << @parked
    end

    it 'should_index_by_name' do
      assert_equal @parked, @collection['parked']
    end

    it 'should_index_by_symbol_name' do
      assert_equal @parked, @collection[:parked]
    end
  end

  context 'WithNumericIndex' do
    before(:each) do
      machine = StateMachines::Machine.new(Class.new)
      @collection = StateMachines::NodeCollection.new(machine, :index => [:name, :value])

      @parked = Node.new(10, 1)
      @collection << @parked
    end

    it 'should_index_by_name' do
      assert_equal @parked, @collection[10]
    end

    it 'should_index_by_string_name' do
      assert_equal @parked, @collection['10']
    end

    it 'should_index_by_symbol_name' do
      assert_equal @parked, @collection[:'10']
    end
  end

  context 'WithPredefinedContexts' do
    before(:each) do
      machine = StateMachines::Machine.new(Class.new)
      @collection = StateMachines::NodeCollection.new(machine)

      @contexts_run = contexts_run = []
      @collection.context([:parked]) { contexts_run << :parked }
      @collection.context([:parked]) { contexts_run << :second_parked }
    end

    it 'should_run_contexts_in_the_order_defined' do
      @collection << Node.new(:parked)
      assert_equal [:parked, :second_parked], @contexts_run
    end

    it 'should_not_run_contexts_if_not_matched' do
      @collection << Node.new(:idling)
      assert_equal [], @contexts_run
    end
  end

  context 'WithPostdefinedContexts' do
    before(:each) do
      machine = StateMachines::Machine.new(Class.new)
      @collection = StateMachines::NodeCollection.new(machine)
      @collection << Node.new(:parked)
    end

    it 'should_run_context_if_matched' do
      contexts_run = []
      @collection.context([:parked]) { contexts_run << :parked }
      assert_equal [:parked], contexts_run
    end

    it 'should_not_run_contexts_if_not_matched' do
      contexts_run = []
      @collection.context([:idling]) { contexts_run << :idling }
      assert_equal [], contexts_run
    end
  end

  context 'WithMatcherContexts' do
    before(:each) do
      machine = StateMachines::Machine.new(Class.new)
      @collection = StateMachines::NodeCollection.new(machine)
      @collection << Node.new(:parked)
    end

    it 'should_always_run_all_matcher_context' do
      contexts_run = []
      @collection.context([StateMachines::AllMatcher.instance]) { contexts_run << :all }
      assert_equal [:all], contexts_run
    end

    it 'should_only_run_blacklist_matcher_if_not_matched' do
      contexts_run = []
      @collection.context([StateMachines::BlacklistMatcher.new([:parked])]) { contexts_run << :blacklist }
      assert_equal [], contexts_run

      @collection << Node.new(:idling)
      assert_equal [:blacklist], contexts_run
    end
  end
end