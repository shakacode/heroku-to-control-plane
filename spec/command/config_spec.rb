# frozen_string_literal: true

require "spec_helper"

describe Command::Config do
  it "displays config for each app" do
    result = run_command("config")

    expect(result[:stdout]).to include("Config for app 'dummy-test'")
    expect(result[:stdout]).to include("Config for app 'dummy-test-with-nothing'")
    expect(result[:stdout]).to include("match_if_app_name_starts_with: true")
  end

  it "displays config for specific app" do
    app = dummy_test_app

    result = run_command("config", "-a", app)

    expect(result[:stdout]).to include("Current config (app '#{app}')")
    expect(result[:stdout]).to include("match_if_app_name_starts_with: true")
  end
end
