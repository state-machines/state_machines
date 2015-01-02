require_relative '../../test_helper'

class MachineWithInstanceHelpersTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @object = @klass.new
  end

  def test_should_not_redefine_existing_public_methods
    @klass.class_eval do
      def park
        true
      end
    end

    @machine.define_helper(:instance, :park) {}
    assert_equal true, @object.park
  end

  def test_should_not_redefine_existing_protected_methods
    @klass.class_eval do
      protected
      def park
        true
      end
    end

    @machine.define_helper(:instance, :park) {}
    assert_equal true, @object.send(:park)
  end

  def test_should_not_redefine_existing_private_methods
    @klass.class_eval do
      private
      def park
        true
      end
    end

    @machine.define_helper(:instance, :park) {}
    assert_equal true, @object.send(:park)
  end

  def test_should_warn_if_defined_in_superclass
    @original_stderr, $stderr = $stderr, StringIO.new

    superclass = Class.new do
      def park
      end
    end
    klass = Class.new(superclass)
    machine = StateMachines::Machine.new(klass)

    machine.define_helper(:instance, :park) {}
    assert_equal "Instance method \"park\" is already defined in #{superclass}, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string
  ensure
    $stderr = @original_stderr
  end

  def test_should_warn_if_defined_in_multiple_superclasses
    @original_stderr, $stderr = $stderr, StringIO.new

    superclass1 = Class.new do
      def park
      end
    end
    superclass2 = Class.new(superclass1) do
      def park
      end
    end
    klass = Class.new(superclass2)
    machine = StateMachines::Machine.new(klass)

    machine.define_helper(:instance, :park) {}
    assert_equal "Instance method \"park\" is already defined in #{superclass1}, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string
  ensure
    $stderr = @original_stderr
  end

  def test_should_warn_if_defined_in_module_prior_to_helper_module
    @original_stderr, $stderr = $stderr, StringIO.new

    mod = Module.new do
      def park
      end
    end
    klass = Class.new do
      include mod
    end
    machine = StateMachines::Machine.new(klass)

    machine.define_helper(:instance, :park) {}
    assert_equal "Instance method \"park\" is already defined in #{mod}, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string
  ensure
    $stderr = @original_stderr
  end

  def test_should_not_warn_if_defined_in_module_after_helper_module
    @original_stderr, $stderr = $stderr, StringIO.new

    klass = Class.new
    machine = StateMachines::Machine.new(klass)

    mod = Module.new do
      def park
      end
    end
    klass.class_eval do
      include mod
    end

    machine.define_helper(:instance, :park) {}
    assert_equal '', $stderr.string
  ensure
    $stderr = @original_stderr
  end

  def test_should_define_if_ignoring_method_conflicts_and_defined_in_superclass
    @original_stderr, $stderr = $stderr, StringIO.new
    StateMachines::Machine.ignore_method_conflicts = true

    superclass = Class.new do
      def park
      end
    end
    klass = Class.new(superclass)
    machine = StateMachines::Machine.new(klass)

    machine.define_helper(:instance, :park) { true }
    assert_equal '', $stderr.string
    assert_equal true, klass.new.park
  ensure
    StateMachines::Machine.ignore_method_conflicts = false
    $stderr = @original_stderr
  end

  def test_should_define_nonexistent_methods
    @machine.define_helper(:instance, :park) { false }
    assert_equal false, @object.park
  end

  def test_should_warn_if_defined_multiple_times
    @original_stderr, $stderr = $stderr, StringIO.new

    @machine.define_helper(:instance, :park) {}
    @machine.define_helper(:instance, :park) {}

    assert_equal "Instance method \"park\" is already defined in #{@klass} :state instance helpers, use generic helper instead or set StateMachines::Machine.ignore_method_conflicts = true.\n", $stderr.string
  ensure
    $stderr = @original_stderr
  end

  def test_should_pass_context_as_arguments
    helper_args = nil
    @machine.define_helper(:instance, :park) { |*args| helper_args = args }
    @object.park
    assert_equal 2, helper_args.length
    assert_equal [@machine, @object], helper_args
  end

  def test_should_pass_method_arguments_through
    helper_args = nil
    @machine.define_helper(:instance, :park) { |*args| helper_args = args }
    @object.park(1, 2, 3)
    assert_equal 5, helper_args.length
    assert_equal [@machine, @object, 1, 2, 3], helper_args
  end

  def test_should_allow_string_evaluation
    @machine.define_helper :instance, <<-end_eval, __FILE__, __LINE__ + 1
      def park
        false
      end
    end_eval
    assert_equal false, @object.park
  end
end

