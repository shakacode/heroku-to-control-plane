# frozen_string_literal: true

require "spec_helper"

describe Command::SetupApp do
  it "raises error if 'setup_app_templates' is not defined" do
    app = dummy_test_app("with-nothing")

    result = run_command("setup-app", "-a", app)

    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Can't find option 'setup_app_templates'")
  end

  it "raises error if app already exists" do
    app = dummy_test_app

    run_command("apply-template", "gvc", "-a", app)
    result = run_command("setup-app", "-a", app)
    run_command("delete", "-a", app, "--yes")

    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("App '#{app}' already exists")
  end

  it "applies templates from 'setup_app_templates'" do
    app = dummy_test_app

    result = run_command("setup-app", "-a", app)
    run_command("delete", "-a", app, "--yes")

    expect(result[:stderr]).to include("Created items")
    expect(result[:stderr]).to include("[app] #{app}")
    expect(result[:stderr]).to include("[identity] #{app}-identity")
    expect(result[:stderr]).to include("[workload] rails")
    expect(result[:stderr]).to include("[volumeset] redis-volume")
    expect(result[:stderr]).to include("[workload] redis")
    expect(result[:stderr]).to include("[volumeset] postgres-volume")
    expect(result[:stderr]).to include("[workload] postgres")
    expect(result[:stderr]).not_to include("Failed to apply templates")
  end
end
