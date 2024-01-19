# frozen_string_literal: true

require "spec_helper"

describe Command::MaintenanceSetPage do
  let(:example_maintenance_page) { "https://example.com/maintenance.html" }

  it "raises error if maintenance workload does not exist" do
    app = dummy_test_app

    run_command("apply-template", "gvc", "-a", app)
    result = run_command("maintenance:set-page", example_maintenance_page, "-a", app)
    run_command("delete", "-a", app, "--yes")

    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Can't find workload 'maintenance'")
  end

  context "when maintenance workload exists" do
    it "does nothing if maintenance workload does not use shakacode image" do
      app = dummy_test_app("with-maintenance-with-non-shakacode-image")

      run_command("apply-template", "gvc", "maintenance-with-non-shakacode-image", "-a", app)
      result = run_command("maintenance:set-page", example_maintenance_page, "-a", app)
      run_command("delete", "-a", app, "--yes")

      expect(result[:stderr])
        .not_to match(/Setting '#{example_maintenance_page}' as the page for maintenance mode[.]+? done!/)
    end

    it "sets page for maintenance workload" do
      app = dummy_test_app

      run_command("apply-template", "gvc", "maintenance", "-a", app)
      result = run_command("maintenance:set-page", example_maintenance_page, "-a", app)
      run_command("delete", "-a", app, "--yes")

      expect(result[:stderr])
        .to match(/Setting '#{example_maintenance_page}' as the page for maintenance mode[.]+? done!/)
    end
  end
end
