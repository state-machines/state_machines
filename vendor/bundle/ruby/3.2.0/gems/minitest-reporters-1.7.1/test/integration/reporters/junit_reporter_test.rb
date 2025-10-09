require_relative "../../test_helper"

module MinitestReportersTest
  class JUnitReporterTest < TestCase
    def test_replaces_special_characters_for_filenames_and_doesnt_crash
      fixtures_directory = File.expand_path('../../../fixtures', __FILE__)
      test_filename = File.join(fixtures_directory, 'junit_filename_bug_example_test.rb')
      output = `ruby #{test_filename} 2>&1`
      refute_match 'No such file or directory', output
    end

    if Gem::Version.new(Minitest::VERSION) >= Gem::Version.new('5.19.0')
      def test_outputs_screenshot_metadata
        test = Minitest::Test.new('test_fail')
        test.define_singleton_method(:test_fail) { assert false }
        test.metadata = { failure_screenshot_path: 'screenshot.png' }

        reporter = Minitest::Reporters::JUnitReporter.new('test/tmp')
        reporter.start
        reporter.record(test.run)
        reporter.report

        test_output = File.read('test/tmp/TEST-Minitest-Test.xml')
        assert_includes test_output, '<system-out>[[ATTACHMENT|screenshot.png]]</system-out>'
      end
    end
  end
end
