# frozen_string_literal: true

require "spec_helper"

describe Command::MaintenanceOn do
  it "raises error if app has no domain" do
    app = dummy_test_app("with-nothing")

    result = run_command("maintenance:on", "-a", app)

    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Can't find domain")
  end

  context "when app has domain" do
    it "raises error if maintenance workload does not exist" do
      app = dummy_test_app

      run_command("apply-template", "gvc", "-a", app)
      result = run_command("maintenance:on", "-a", app)
      run_command("delete", "-a", app, "--yes")

      expect(result[:status]).to be(1)
      expect(result[:stderr]).to include("Can't find workload 'maintenance'")
    end

    context "when maintenance workload exists" do
      let(:app) { dummy_test_app }

      before do
        run_command("apply-template", "gvc", "rails", "redis", "postgres", "maintenance", "-a", app)
        run_command("build-image", "-a", app)
        run_command("deploy-image", "-a", app)
        run_command("ps:start", "-a", app, "--wait")
      end

      after do
        run_command("delete", "-a", app, "--yes")
      end

      it "does nothing if maintenance mode is already enabled" do
        allow(Kernel).to receive(:sleep)

        run_command("maintenance:on", "-a", app)
        result = run_command("maintenance:on", "-a", app)

        expect(result[:stderr]).to include("Maintenance mode is already enabled for app '#{app}'")
      end

      it "enables maintenance mode" do
        allow(Kernel).to receive(:sleep)

        result = run_command("maintenance:on", "-a", app)

        expect(result[:stderr]).to include("Maintenance mode enabled for app '#{app}'")
      end
    end
  end
end
