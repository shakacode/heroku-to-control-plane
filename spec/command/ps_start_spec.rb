# frozen_string_literal: true

require "spec_helper"

describe Command::PsStart do
  let(:app) { dummy_test_app }

  before do
    run_command("apply-template", "gvc", "rails", "redis", "postgres", "-a", app)
    run_command("build-image", "-a", app)
    run_command("deploy-image", "-a", app)
  end

  after do
    run_command("delete", "-a", app, "--yes")
  end

  it "starts all workloads" do
    result = run_command("ps:start", "-a", app)

    expect(result[:stderr]).to match(/Starting workload 'rails'[.]+? done!/)
    expect(result[:stderr]).to match(/Starting workload 'redis'[.]+? done!/)
    expect(result[:stderr]).to match(/Starting workload 'postgres'[.]+? done!/)
  end

  it "starts specific workload" do
    result = run_command("ps:start", "-a", app, "--workload", "rails")

    expect(result[:stderr]).to match(/Starting workload 'rails'[.]+? done!/)
    expect(result[:stderr]).not_to include("redis")
    expect(result[:stderr]).not_to include("postgres")
  end

  it "starts all workloads and waits for them to be ready" do
    result = run_command("ps:start", "-a", app, "--wait")

    expect(result[:stderr]).to match(/Starting workload 'rails'[.]+? done!/)
    expect(result[:stderr]).to match(/Starting workload 'redis'[.]+? done!/)
    expect(result[:stderr]).to match(/Starting workload 'postgres'[.]+? done!/)
    expect(result[:stderr]).to match(/Waiting for workload 'rails' to be ready[.]+? done!/)
    expect(result[:stderr]).to match(/Waiting for workload 'redis' to be ready[.]+? done!/)
    expect(result[:stderr]).to match(/Waiting for workload 'postgres' to be ready[.]+? done!/)
  end
end
