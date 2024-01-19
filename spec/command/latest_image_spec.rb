# frozen_string_literal: true

require "spec_helper"

describe Command::LatestImage do
  it "displays default image for app if no image has been built" do
    app = dummy_test_app

    result = run_command("latest-image", "-a", app)

    expect(result[:stdout]).to include("#{app}:NO_IMAGE_AVAILABLE")
  end

  it "displays latest image for app if images have been built" do
    app = dummy_test_app

    run_command("apply-template", "gvc", "-a", app)
    run_command("build-image", "-a", app)
    run_command("build-image", "-a", app)
    result = run_command("latest-image", "-a", app)
    run_command("delete", "-a", app, "--yes")

    expect(result[:stdout]).to include("#{app}:2")
  end
end
