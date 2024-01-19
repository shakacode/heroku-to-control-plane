# frozen_string_literal: true

require "spec_helper"

describe Command::PsStop do
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

  it "stops all workloads" do
    result = run_command("ps:stop", "-a", app)

    expect(result[:stderr]).to match(/Stopping workload 'rails'[.]+? done!/)
    expect(result[:stderr]).to match(/Stopping workload 'redis'[.]+? done!/)
    expect(result[:stderr]).to match(/Stopping workload 'postgres'[.]+? done!/)
  end

  it "stops specific workload" do
    result = run_command("ps:stop", "-a", app, "--workload", "rails")

    expect(result[:stderr]).to match(/Stopping workload 'rails'[.]+? done!/)
    expect(result[:stderr]).not_to include("redis")
    expect(result[:stderr]).not_to include("postgres")
  end

  it "stops all workloads and waits for them to not be ready" do
    result = run_command("ps:stop", "-a", app, "--wait")

    expect(result[:stderr]).to match(/Stopping workload 'rails'[.]+? done!/)
    expect(result[:stderr]).to match(/Stopping workload 'redis'[.]+? done!/)
    expect(result[:stderr]).to match(/Stopping workload 'postgres'[.]+? done!/)
    expect(result[:stderr]).to match(/Waiting for workload 'rails' to not be ready[.]+? done!/)
    expect(result[:stderr]).to match(/Waiting for workload 'redis' to not be ready[.]+? done!/)
    expect(result[:stderr]).to match(/Waiting for workload 'postgres' to not be ready[.]+? done!/)
  end
end
