# frozen_string_literal: true

require "spec_helper"

describe Command::PsWait do
  let(:app) { dummy_test_app }

  before do
    run_command("apply-template", "gvc", "rails", "redis", "postgres", "-a", app)
    run_command("build-image", "-a", app)
    run_command("deploy-image", "-a", app)
    run_command("ps:start", "-a", app, "--wait")
    run_command("ps:restart", "-a", app)
  end

  after do
    run_command("delete", "-a", app, "--yes")
  end

  it "waits for all workloads to be ready" do
    result = run_command("ps:wait", "-a", app)

    expect(result[:stderr]).to match(/Waiting for workload 'rails' to be ready[.]+? done!/)
    expect(result[:stderr]).to match(/Waiting for workload 'redis' to be ready[.]+? done!/)
    expect(result[:stderr]).to match(/Waiting for workload 'postgres' to be ready[.]+? done!/)
  end

  it "waits for specific workload to be ready" do
    result = run_command("ps:wait", "-a", app, "--workload", "rails")

    expect(result[:stderr]).to match(/Waiting for workload 'rails' to be ready[.]+? done!/)
    expect(result[:stderr]).not_to include("redis")
    expect(result[:stderr]).not_to include("postgres")
  end
end
