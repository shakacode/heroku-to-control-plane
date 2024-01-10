# frozen_string_literal: true

require "securerandom"

module CommandHelpers
  DUMMY_TEST_APP_PREFIX = "dummy-test"

  def dummy_test_app(extra_prefix = "")
    prefix = "#{DUMMY_TEST_APP_PREFIX}-"
    prefix += "#{extra_prefix}-" unless extra_prefix.empty?
    random_suffix = SecureRandom.hex(4)

    "#{prefix}#{random_suffix}"
  end

  def run_command(*args) # rubocop:disable Metrics/MethodLength
    result = {
      status: 0,
      stderr: "",
      stdout: ""
    }

    original_stderr = $stderr
    original_stdout = $stdout

    $stderr = Tempfile.create
    $stdout = Tempfile.create

    begin
      Cpl::Cli.start(args)

      result[:status] = $CHILD_STATUS.exitstatus
    rescue SystemExit => e
      result[:status] = e.status
    end

    $stderr.rewind
    result[:stderr] = $stderr.read
    $stderr.close

    $stdout.rewind
    result[:stdout] = $stdout.read
    $stdout.close

    $stderr = original_stderr
    $stdout = original_stdout

    result
  end
end
