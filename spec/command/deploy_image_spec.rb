# frozen_string_literal: true

require "spec_helper"

describe Command::DeployImage do
  it "raises error if any of the app workloads does not exist" do
    app = dummy_test_app

    run_command("apply-template", "gvc", "-a", app)
    run_command("build-image", "-a", app)
    result = run_command("deploy-image", "-a", app)
    run_command("delete", "-a", app, "--yes")

    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Can't find workload 'rails'")
  end

  it "deploys latest image to app workloads" do
    app = dummy_test_app("with-rails-with-non-app-image")

    run_command("apply-template", "gvc", "rails", "rails-with-non-app-image", "-a", app)
    run_command("build-image", "-a", app)
    result = run_command("deploy-image", "-a", app)
    run_command("delete", "-a", app, "--yes")

    expect(result[:stderr]).to match(%r{rails: https://rails-.+?.cpln.app})
    expect(result[:stderr]).not_to include("rails-with-non-app-image")
  end
end
