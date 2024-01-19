# frozen_string_literal: true

require "spec_helper"

describe Command::Delete do
  it "displays message if app does not exist" do
    app = dummy_test_app

    result = run_command("delete", "-a", app)

    expect(result[:stderr]).to include("App '#{app}' does not exist")
  end

  it "asks for confirmation and does nothing" do
    allow(Shell).to receive(:confirm).and_return(false)

    app = dummy_test_app

    run_command("apply-template", "gvc", "-a", app)
    result = run_command("delete", "-a", app)

    expect(Shell).to have_received(:confirm).with(include(app)).once
    expect(result[:stderr]).not_to match(/Deleting app '#{app}'[.]+? done!/)
  end

  it "asks for confirmation and deletes app" do
    allow(Shell).to receive(:confirm).and_return(true)

    app = dummy_test_app

    run_command("apply-template", "gvc", "-a", app)
    result = run_command("delete", "-a", app)

    expect(Shell).to have_received(:confirm).with(include(app)).once
    expect(result[:stderr]).to include("No volumesets to delete")
    expect(result[:stderr]).to include("No images to delete")
    expect(result[:stderr]).to match(/Deleting app '#{app}'[.]+? done!/)
  end

  it "skips confirmation and deletes app" do
    allow(Shell).to receive(:confirm).and_return(false)

    app = dummy_test_app

    run_command("apply-template", "gvc", "-a", app)
    result = run_command("delete", "-a", app, "--yes")

    expect(Shell).not_to have_received(:confirm)
    expect(result[:stderr]).to include("No volumesets to delete")
    expect(result[:stderr]).to include("No images to delete")
    expect(result[:stderr]).to match(/Deleting app '#{app}'[.]+? done!/)
  end

  it "deletes app with volumesets and images" do
    allow(Shell).to receive(:confirm).and_return(true)

    app = dummy_test_app

    run_command("apply-template", "gvc", "rails", "redis", "detached-volume", "-a", app)
    run_command("build-image", "-a", app)
    result = run_command("delete", "-a", app, "--yes")

    expect(result[:stderr]).to match(/Deleting volumeset 'detached-volume'[.]+? done!/)
    expect(result[:stderr]).to match(/Deleting volumeset 'redis-volume'[.]+? done!/)
    expect(result[:stderr]).to match(/Deleting app '#{app}'[.]+? done!/)
    expect(result[:stderr]).to match(/Deleting image '#{app}:1'[.]+? done!/)
  end
end
