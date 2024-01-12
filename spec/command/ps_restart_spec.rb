# frozen_string_literal: true

require "spec_helper"

describe Command::PsRestart do
  it "raises error if any of the workloads does not exist" do
    app = dummy_test_app

    run_command("apply-template", "gvc", "-a", app)
    run_command("build-image", "-a", app)
    run_command("deploy-image", "-a", app)
    run_command("ps:start", "-a", app, "--wait")
    result = run_command("ps:restart", "-a", app)
    run_command("delete", "-a", app, "--yes")

    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Can't find workload 'rails'")
  end

  context "when workloads exist" do
    let(:app) { dummy_test_app }

    before do
      run_command("apply-template", "gvc", "rails", "redis", "postgres", "-a", app)
      run_command("build-image", "-a", app)
      run_command("deploy-image", "-a", app)
      run_command("ps:start", "-a", app, "--wait")
    end

    after do
      run_command("delete", "-a", app, "--yes")
    end

    it "restarts all workloads" do
      result = run_command("ps:restart", "-a", app)

      expect(result[:stderr]).to match(/Restarting workload 'rails'[.]+? done!/)
      expect(result[:stderr]).to match(/Restarting workload 'redis'[.]+? done!/)
      expect(result[:stderr]).to match(/Restarting workload 'postgres'[.]+? done!/)
    end

    it "restarts specific workload" do
      result = run_command("ps:restart", "-a", app, "--workload", "rails")

      expect(result[:stderr]).to match(/Restarting workload 'rails'[.]+? done!/)
      expect(result[:stderr]).not_to include("redis")
      expect(result[:stderr]).not_to include("postgres")
    end
  end
end
