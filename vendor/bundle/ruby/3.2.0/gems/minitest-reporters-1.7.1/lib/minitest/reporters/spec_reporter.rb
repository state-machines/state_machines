module Minitest
  module Reporters
    # Turn-like reporter that reads like a spec.
    #
    # Based upon TwP's turn (MIT License) and paydro's monkey-patch.
    #
    # @see https://github.com/TwP/turn turn
    # @see https://gist.github.com/356945 paydro's monkey-patch
    class SpecReporter < BaseReporter
      include ANSI::Code
      include RelativePosition

      # The constructor takes an `options` hash
      # @param options [Hash]
      # @option options print_failure_summary [Boolean] whether to print the errors at the bottom of the
      #   report.
      # @option options suppress_inline_failure_output [Boolean] whether to suppress the printing of errors
      #   inline with the test results as they occur.
      #
      def initialize(options = {})
        super
        @print_failure_summary = options[:print_failure_summary]
        @suppress_inline_failure_output = options[:suppress_inline_failure_output]
      end

      def start
        super
        puts('Started with run options %s' % options[:args])
        puts
      end

      def report
        super
        if @print_failure_summary
          failed_test_groups = tests.reject { |test| test.failures.empty? }
                                    .sort_by { |test| [test_class(test).to_s, test.name] }
                                    .group_by { |test| test_class(test).to_s }
          unless failed_test_groups.empty?
            print(red('Failures and errors:'))

            failed_test_groups.each { |name, tests| print_failure(name, tests) }
          end
        end

        puts('Finished in %.5fs' % total_time)
        print('%d tests, %d assertions, ' % [count, assertions])
        color = failures.zero? && errors.zero? ? :green : :red
        print(send(color) { '%d failures, %d errors, ' } % [failures, errors])
        print(yellow { '%d skips' } % skips)
        puts
      end

      def record(test)
        super
        record_print_status(test)
        record_print_failures_if_any(test) unless @suppress_inline_failure_output
      end

      protected

      def before_suite(suite)
        puts suite
      end

      def after_suite(_suite)
        puts
      end

      def print_failure(name, tests)
        puts
        puts name
        tests.each do |test|
          record_print_status(test)
          print_info(test.failure, test.error?)
          puts
        end
      end

      def record_print_failures_if_any(test)
        if !test.skipped? && test.failure
          print_info(test.failure, test.error?)
          puts
        end
      end

      def record_print_status(test)
        test_name = test.name.gsub(/^test_: /, 'test:')
        print pad_test(test_name)
        print_colored_status(test)
        print(" (%.2fs)" % test.time) unless test.time.nil?
        puts
      end
    end
  end
end
