# frozen_string_literal: true

require "spec_helper"

describe Command::Env do
  it "raises error if app does not exist" do
    app = dummy_test_app

    result = run_command("env", "-a", app)

    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Can't find app '#{app}'")
  end

  it "displays app-specific environment variables" do
    app = dummy_test_app

    run_command("apply-template", "gvc", "-a", app)
    result = run_command("env", "-a", app)
    run_command("delete", "-a", app, "--yes")

    expect(result[:stdout]).to include("REDIS_URL=redis://redis.#{app}.cpln.local:6379")
    expect(result[:stdout])
      .to include("DATABASE_URL=postgres://postgres:password@postgres.#{app}.cpln.local:5432/#{app}")
  end
end
