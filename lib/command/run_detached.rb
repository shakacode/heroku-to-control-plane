# frozen_string_literal: true

module Command
  class RunDetached < Base # rubocop:disable Metrics/ClassLength
    NAME = "run:detached"
    USAGE = "run:detached COMMAND"
    REQUIRES_ARGS = true
    OPTIONS = [
      app_option(required: true),
      image_option,
      workload_option,
      location_option,
      use_local_token_option,
      clean_on_failure_option
    ].freeze
    DESCRIPTION = "Runs one-off **_non-interactive_** replicas (close analog of `heroku run:detached`)"
    LONG_DESCRIPTION = <<~DESC
      - Runs one-off **_non-interactive_** replicas (close analog of `heroku run:detached`)
      - Uses `Cron` workload type with log async fetching
      - Implemented with only async execution methods, more suitable for production tasks
      - Has alternative log fetch implementation with only JSON-polling and no WebSockets
      - Less responsive but more stable, useful for CI tasks
      - Deletes the workload whenever finished with success
      - Deletes the workload whenever finished with failure by default
      - Use `--no-clean-on-failure` to disable cleanup to help with debugging failed runs
    DESC
    EXAMPLES = <<~EX
      ```sh
      cpl run:detached rails db:prepare -a $APP_NAME

      # Need to quote COMMAND if setting ENV value or passing args.
      cpl run:detached -a $APP_NAME -- 'LOG_LEVEL=warn rails db:migrate'

      # Uses a different image (which may not be promoted yet).
      cpl run:detached -a $APP_NAME --image appimage:123 -- rails db:migrate # Exact image name
      cpl run:detached -a $APP_NAME --image latest -- rails db:migrate       # Latest sequential image

      # Uses a different workload than `one_off_workload` from `.controlplane/controlplane.yml`.
      cpl run:detached -a $APP_NAME -w other-workload -- rails db:migrate:status

      # Overrides remote CPLN_TOKEN env variable with local token.
      # Useful when superuser rights are needed in remote container.
      cpl run:detached -a $APP_NAME --use-local-token -- rails db:migrate:status
      ```
    EX

    WORKLOAD_SLEEP_CHECK = 2

    attr_reader :location, :workload_to_clone, :workload_clone, :container

    def call
      @location = config.location
      @workload_to_clone = config.options["workload"] || config[:one_off_workload]
      @workload_clone = "#{workload_to_clone}-runner-#{random_four_digits}"

      step("Cloning workload '#{workload_to_clone}' on app '#{config.options[:app]}' to '#{workload_clone}'") do
        clone_workload
      end

      wait_for_workload(workload_clone)
      show_logs_waiting
    ensure
      exit(1) if @crashed
    end

    private

    def clone_workload # rubocop:disable Metrics/MethodLength
      # Get base specs of workload
      spec = cp.fetch_workload!(workload_to_clone).fetch("spec")
      container_spec = spec["containers"].detect { _1["name"] == workload_to_clone } || spec["containers"].first
      @container = container_spec["name"]

      # remove other containers if any
      spec["containers"] = [container_spec]

      # Set runner
      container_spec["command"] = "bash"
      container_spec["args"] = ["-c", 'eval "$CONTROLPLANE_RUNNER"']

      # Ensure one-off workload will be running
      spec["defaultOptions"]["suspend"] = false

      # Ensure no scaling
      spec["defaultOptions"]["autoscaling"]["minScale"] = 1
      spec["defaultOptions"]["autoscaling"]["maxScale"] = 1
      spec["defaultOptions"]["capacityAI"] = false

      # Override image if specified
      image = config.options[:image]
      image = latest_image if image == "latest"
      container_spec["image"] = "/org/#{config.org}/image/#{image}" if image

      # Set cron job props
      spec["type"] = "cron"
      spec["job"] = { "schedule" => "* * * * *", "restartPolicy" => "Never" }
      spec["defaultOptions"]["autoscaling"] = {}
      container_spec.delete("ports")

      container_spec["env"] ||= []
      container_spec["env"] << { "name" => "CONTROLPLANE_TOKEN",
                                 "value" => ControlplaneApiDirect.new.api_token[:token] }
      container_spec["env"] << { "name" => "CONTROLPLANE_RUNNER", "value" => runner_script }

      # Create workload clone
      cp.apply_hash("kind" => "workload", "name" => workload_clone, "spec" => spec)
    end

    def runner_script # rubocop:disable Metrics/MethodLength
      script = "echo '-- STARTED RUNNER SCRIPT --'\n"
      script += Scripts.helpers_cleanup

      if config.options["use_local_token"]
        script += <<~SHELL
          CPLN_TOKEN=$CONTROLPLANE_TOKEN
        SHELL
      end

      script += <<~SHELL
        crashed=0
        if ! eval "#{args_join(config.args)}"; then
          crashed=1
          echo "----- CRASHED -----"
        fi
        clean_on_failure=#{config.options[:clean_on_failure] ? 1 : 0}
        if [ $crashed -eq 0 ] || [ $clean_on_failure -eq 1 ]; then
          echo "-- FINISHED RUNNER SCRIPT, DELETING WORKLOAD --"
          sleep 30 # grace time for logs propagation
          curl ${CPLN_ENDPOINT}${CPLN_WORKLOAD} -H "Authorization: ${CONTROLPLANE_TOKEN}" -X DELETE -s -o /dev/null
          while true; do sleep 1; done # wait for SIGTERM
        else
          echo "-- FINISHED RUNNER SCRIPT --"
        fi
      SHELL

      script
    end

    def show_logs_waiting # rubocop:disable Metrics/MethodLength
      progress.puts("Scheduled, fetching logs (it's a cron job, so it may take up to a minute to start)...\n\n")
      begin
        @finished = false
        while cp.fetch_workload(workload_clone) && !@finished
          sleep(WORKLOAD_SLEEP_CHECK)
          print_uniq_logs
        end
      rescue RuntimeError => e
        progress.puts(Shell.color("ERROR: #{e}", :red))
        retry
      end
      progress.puts("\nFinished workload and logger.")
    end

    def print_uniq_logs
      @printed_log_entries ||= []
      ts = Time.now.to_i
      entries = normalized_log_entries(from: ts - 60, to: ts)

      (entries - @printed_log_entries).sort.each do |(_ts, val)|
        @crashed = true if val.match?(/^----- CRASHED -----$/)
        @finished = true if val.match?(/^-- FINISHED RUNNER SCRIPT(, DELETING WORKLOAD)? --$/)
        puts val
      end

      @printed_log_entries = entries # as well truncate old entries if any
    end

    def normalized_log_entries(from:, to:)
      log = cp.log_get(workload: workload_clone, from: from, to: to)

      log["data"]["result"]
        .each_with_object([]) { |obj, result| result.concat(obj["values"]) }
        .select { |ts, _val| ts[..-10].to_i > from }
    end
  end
end
