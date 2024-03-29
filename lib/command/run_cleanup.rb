# frozen_string_literal: true

module Command
  class RunCleanup < Base
    NAME = "run:cleanup"
    OPTIONS = [
      app_option(required: true),
      skip_confirm_option
    ].freeze
    DESCRIPTION = "Deletes stale run workloads for an app"
    LONG_DESCRIPTION = <<~DESC
      - Deletes stale run workloads for an app
      - Workloads are considered stale based on how many days since created
      - `stale_run_workload_created_days` in the `.controlplane/controlplane.yml` file specifies the number of days after created that the workload is considered stale
      - Works for both interactive workloads (created with `cpl run`) and non-interactive workloads (created with `cpl run:detached`)
      - Will ask for explicit user confirmation of deletion
    DESC

    def call # rubocop:disable Metrics/MethodLength
      return progress.puts("No stale run workloads found.") if stale_run_workloads.empty?

      progress.puts("Stale run workloads:")
      stale_run_workloads.each do |workload|
        output = ""
        output += if config.should_app_start_with?(config.app)
                    "  #{workload[:app]} - #{workload[:name]}"
                  else
                    "  #{workload[:name]}"
                  end
        output += " (#{Shell.color("#{workload[:date]} - #{workload[:days]} days ago", :red)})"
        progress.puts(output)
      end

      return unless confirm_delete

      progress.puts
      stale_run_workloads.each do |workload|
        delete_workload(workload)
      end
    end

    private

    def app_matches?(app, app_name, app_options)
      app == app_name.to_s || (app_options[:match_if_app_name_starts_with] && app.start_with?(app_name.to_s))
    end

    def find_app_options(app)
      @app_options ||= {}
      @app_options[app] ||= config.apps.find do |app_name, app_options|
                              app_matches?(app, app_name, app_options)
                            end&.last
    end

    def find_workloads(app)
      app_options = find_app_options(app)
      return [] if app_options.nil?

      (app_options[:app_workloads] + app_options[:additional_workloads] + [app_options[:one_off_workload]]).uniq
    end

    def stale_run_workloads # rubocop:disable Metrics/MethodLength
      @stale_run_workloads ||=
        begin
          defined_workloads = find_workloads(config.app)

          run_workloads = []

          now = DateTime.now
          stale_run_workload_created_days = config[:stale_run_workload_created_days]

          interactive_workloads = cp.query_workloads("-run-", partial_workload_match: true)["items"]
          non_interactive_workloads = cp.query_workloads("-runner-", partial_workload_match: true)["items"]
          workloads = interactive_workloads + non_interactive_workloads

          workloads.each do |workload|
            app_name = workload["links"].find { |link| link["rel"] == "gvc" }["href"].split("/").last
            workload_name = workload["name"]

            original_workload_name, workload_number = workload_name.split(/-run-|-runner-/)
            next unless defined_workloads.include?(original_workload_name) && workload_number.match?(/^\d{4}$/)

            created_date = DateTime.parse(workload["created"])
            diff_in_days = (now - created_date).to_i
            next unless diff_in_days >= stale_run_workload_created_days

            run_workloads.push({
                                 app: app_name,
                                 name: workload_name,
                                 date: created_date,
                                 days: diff_in_days
                               })
          end

          run_workloads
        end
    end

    def confirm_delete
      return true if config.options[:yes]

      Shell.confirm("\nAre you sure you want to delete these #{stale_run_workloads.length} run workloads?")
    end

    def delete_workload(workload)
      message = if config.should_app_start_with?(config.app)
                  "Deleting run workload '#{workload[:app]} - #{workload[:name]}'"
                else
                  "Deleting run workload '#{workload[:name]}'"
                end
      step(message) do
        cp.delete_workload(workload[:name], workload[:app])
      end
    end
  end
end
