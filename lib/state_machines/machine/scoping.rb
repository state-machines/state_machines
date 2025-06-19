# frozen_string_literal: true

module StateMachines
  class Machine
    module Scoping
      protected

      # Defines the with/without scope helpers for this attribute.  Both the
      # singular and plural versions of the attribute are defined for each
      # scope helper.  A custom plural can be specified if it cannot be
      # automatically determined by either calling +pluralize+ on the attribute
      # name or adding an "s" to the end of the name.
      def define_scopes(custom_plural = nil)
        plural = custom_plural || pluralize(name)

        %i[with without].each do |kind|
          [name, plural].map(&:to_s).uniq.each do |suffix|
            method = "#{kind}_#{suffix}"

            next unless (scope = send("create_#{kind}_scope", method))

            # Converts state names to their corresponding values so that they
            # can be looked up properly
            define_helper(:class, method) do |machine, klass, *states|
              run_scope(scope, machine, klass, states)
            end
          end
        end
      end

      # Creates a scope for finding objects *with* a particular value or values
      # for the attribute.
      #
      # By default, this is a no-op.
      def create_with_scope(name); end

      # Creates a scope for finding objects *without* a particular value or
      # values for the attribute.
      #
      # By default, this is a no-op.
      def create_without_scope(name); end
    end
  end
end
