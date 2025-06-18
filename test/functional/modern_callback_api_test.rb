# frozen_string_literal: true

require 'test_helper'

class ModernCallbackApiTest < StateMachinesTest
  def setup
    @model = Class.new do
      attr_accessor :submitted_at, :approved_at, :rejected_at, :published_at, :callback_log

      def initialize
        @callback_log = []
        super
      end

      state_machine :status, initial: :draft do
        event :submit do
          transition draft: :pending
        end

        event :approve do
          transition pending: :approved
        end

        event :reject do
          transition pending: :rejected
        end

        event :publish do
          transition approved: :published
        end

        # Modern keyword argument style - cleaner and more explicit
        before_transition(from: :draft, to: :pending, do: :validate_submission)
        before_transition(from: :pending, to: :approved, if: :meets_criteria?, do: :validate_approval)

        # Pattern matching in callback blocks showcases Ruby 3.2+ features
        before_transition do |object, transition|
          case [transition.from_name, transition.to_name, transition.event]
          when %i[draft pending submit]
            object.submitted_at = Time.zone.now
            object.callback_log << 'submitting for review'
          when %i[pending approved approve]
            object.approved_at = Time.zone.now
            object.callback_log << 'approving submission'
          when %i[pending rejected reject]
            object.rejected_at = Time.zone.now
            object.callback_log << 'rejecting submission'
          when %i[approved published publish]
            object.published_at = Time.zone.now
            object.callback_log << 'publishing content'
          else
            object.callback_log << "transition: #{transition.from} -> #{transition.to} via #{transition.event}"
          end
        end

        # Mixed style: legacy positional args with modern pattern matching
        after_transition :notify_stakeholders do |object, transition|
          # Modern pattern matching for notification logic
          object.callback_log << case transition.to_name
                                 when :published
                                   'sending publication notifications'
                                 when :rejected
                                   'sending rejection notifications'
                                 else
                                   "status changed to #{transition.to_name}"
                                 end
        end

        # Modern keyword style with multiple conditions
        around_transition(from: :pending, on: %i[approve reject]) do |object, _transition, block|
          object.callback_log << 'starting review process'
          start_time = Time.zone.now

          block.call # Execute the transition

          duration = Time.zone.now - start_time
          object.callback_log << "review completed in #{duration.round(2)} seconds"
        end
      end

      private

      def validate_submission
        callback_log << 'validating submission'
      end

      def meets_criteria?
        callback_log << 'checking approval criteria'
        true # Simplified for test
      end

      def validate_approval
        callback_log << 'validating approval'
      end

      def notify_stakeholders
        callback_log << 'notifying stakeholders'
      end
    end

    @workflow = @model.new
  end

  def test_should_support_modern_keyword_arguments
    assert_equal 'draft', @workflow.status
    assert_empty @workflow.callback_log

    # Test submit transition with modern callbacks
    @workflow.submit

    assert_equal 'pending', @workflow.status
    assert_includes @workflow.callback_log, 'validating submission'
    assert_includes @workflow.callback_log, 'submitting for review'
    assert_includes @workflow.callback_log, 'notifying stakeholders'
    assert_includes @workflow.callback_log, 'status changed to pending'
    assert_not_nil @workflow.submitted_at
  end

  def test_should_support_pattern_matching_in_callbacks
    @workflow.submit
    @workflow.approve

    assert_equal 'approved', @workflow.status
    assert_includes @workflow.callback_log, 'checking approval criteria'
    assert_includes @workflow.callback_log, 'validating approval'
    assert_includes @workflow.callback_log, 'approving submission'
    assert_includes @workflow.callback_log, 'starting review process'
    assert(@workflow.callback_log.any? { |log| log.start_with?('review completed in') })
    assert_not_nil @workflow.approved_at
  end

  def test_should_support_mixed_callback_styles
    @workflow.submit
    @workflow.approve
    @workflow.publish

    assert_equal 'published', @workflow.status
    assert_includes @workflow.callback_log, 'publishing content'
    assert_includes @workflow.callback_log, 'sending publication notifications'
    assert_not_nil @workflow.published_at
  end

  def test_should_maintain_backward_compatibility_with_legacy_callbacks
    model = Class.new do
      attr_accessor :callback_log

      def initialize
        @callback_log = []
        super
      end

      state_machine :status, initial: :draft do
        event :submit do
          transition draft: :pending
        end

        # All legacy callback styles should still work
        before_transition :log_before_any
        before_transition draft: :pending, do: :log_submit
        before_transition on: :submit, do: [:log_event_submit]
        before_transition from: :draft, to: :pending, if: :should_log?, do: :log_conditional
      end

      private

      def log_before_any
        callback_log << 'before any'
      end

      def log_submit
        callback_log << 'submit transition'
      end

      def log_event_submit
        callback_log << 'submit event'
      end

      def log_conditional
        callback_log << 'conditional callback'
      end

      def should_log?
        true
      end
    end

    workflow = model.new
    workflow.submit

    assert_equal 'pending', workflow.status
    assert_includes workflow.callback_log, 'before any'
    assert_includes workflow.callback_log, 'submit transition'
    assert_includes workflow.callback_log, 'submit event'
    assert_includes workflow.callback_log, 'conditional callback'
  end

  def test_should_support_block_only_callbacks
    model = Class.new do
      attr_accessor :callback_log

      def initialize
        @callback_log = []
        super
      end

      state_machine :status, initial: :draft do
        event :submit do
          transition draft: :pending
        end

        # Block-only callback should work
        before_transition do |object|
          object.callback_log << 'block only callback'
        end
      end
    end

    workflow = model.new
    workflow.submit

    assert_equal 'pending', workflow.status
    assert_includes workflow.callback_log, 'block only callback'
  end

  def test_should_support_pure_keyword_style_without_positional_args
    model = Class.new do
      attr_accessor :callback_log

      def initialize
        @callback_log = []
        super
      end

      state_machine :status, initial: :draft do
        event :submit do
          transition draft: :pending
        end

        # Pure keyword arguments without any positional args
        before_transition(from: :draft, to: :pending, do: :log_pure_keyword)
        before_transition(on: :submit, if: :should_log?, do: :log_event_keyword)
      end

      private

      def log_pure_keyword
        callback_log << 'pure keyword callback'
      end

      def log_event_keyword
        callback_log << 'event keyword callback'
      end

      def should_log?
        true
      end
    end

    workflow = model.new
    workflow.submit

    assert_equal 'pending', workflow.status
    assert_includes workflow.callback_log, 'pure keyword callback'
    assert_includes workflow.callback_log, 'event keyword callback'
  end
end
