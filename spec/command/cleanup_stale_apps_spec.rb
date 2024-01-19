# frozen_string_literal: true

require "spec_helper"

describe Command::CleanupStaleApps do
  it "raises error if 'stale_app_image_deployed_days' is not defined" do
    app = dummy_test_app("with-nothing")

    result = run_command("cleanup-stale-apps", "-a", app)

    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Can't find option 'stale_app_image_deployed_days'")
  end

  it "displays message if there are no stale apps to delete" do
    app = dummy_test_app

    result = run_command("cleanup-stale-apps", "-a", app)

    expect(result[:stderr]).to include("No stale apps found")
  end

  context "when there are stale apps to delete" do
    it "lists stale apps" do
      allow(Shell).to receive(:confirm).and_return(false)

      first_app_with_old_image = dummy_test_app
      second_app_with_old_image = dummy_test_app
      app_with_new_image = dummy_test_app
      app_without_image = dummy_test_app

      run_command("apply-template", "gvc", "-a", first_app_with_old_image)
      run_command("apply-template", "gvc", "-a", second_app_with_old_image)
      run_command("apply-template", "gvc", "-a", app_with_new_image)
      run_command("apply-template", "gvc", "-a", app_without_image)
      run_command("build-image", "-a", first_app_with_old_image)
      run_command("build-image", "-a", second_app_with_old_image)
      travel_to_days_later(30)
      run_command("build-image", "-a", app_with_new_image)
      result = run_command("cleanup-stale-apps", "-a", CommandHelpers::DUMMY_TEST_APP_PREFIX)
      travel_back
      run_command("delete", "-a", first_app_with_old_image, "--yes")
      run_command("delete", "-a", second_app_with_old_image, "--yes")
      run_command("delete", "-a", app_with_new_image, "--yes")
      run_command("delete", "-a", app_without_image, "--yes")

      expect(Shell).to have_received(:confirm).with(include("2 apps")).once
      expect(result[:stderr]).to include(first_app_with_old_image)
      expect(result[:stderr]).to include(second_app_with_old_image)
      expect(result[:stderr]).not_to include(app_with_new_image)
      expect(result[:stderr]).not_to include(app_without_image)
    end

    it "asks for confirmation and deletes stale apps" do
      allow(Shell).to receive(:confirm).and_return(true)

      first_app = dummy_test_app
      second_app = dummy_test_app

      run_command("apply-template", "gvc", "-a", first_app)
      run_command("apply-template", "gvc", "-a", second_app)
      run_command("build-image", "-a", first_app)
      run_command("build-image", "-a", second_app)
      travel_to_days_later(30)
      result = run_command("cleanup-stale-apps", "-a", CommandHelpers::DUMMY_TEST_APP_PREFIX)
      travel_back
      run_command("delete", "-a", first_app, "--yes")
      run_command("delete", "-a", second_app, "--yes")

      expect(Shell).to have_received(:confirm).with(include("2 apps")).once
      expect(result[:stderr]).to match(/Deleting app '#{first_app}'[.]+? done!/)
      expect(result[:stderr]).to match(/Deleting image '#{first_app}:1'[.]+? done!/)
      expect(result[:stderr]).to match(/Deleting app '#{second_app}'[.]+? done!/)
      expect(result[:stderr]).to match(/Deleting image '#{second_app}:1'[.]+? done!/)
    end

    it "skips confirmation and deletes stale apps" do
      allow(Shell).to receive(:confirm).and_return(false)

      first_app = dummy_test_app
      second_app = dummy_test_app

      run_command("apply-template", "gvc", "-a", first_app)
      run_command("apply-template", "gvc", "-a", second_app)
      run_command("build-image", "-a", first_app)
      run_command("build-image", "-a", second_app)
      travel_to_days_later(30)
      result = run_command("cleanup-stale-apps", "-a", CommandHelpers::DUMMY_TEST_APP_PREFIX, "--yes")
      travel_back
      run_command("delete", "-a", first_app, "--yes")
      run_command("delete", "-a", second_app, "--yes")

      expect(Shell).not_to have_received(:confirm)
      expect(result[:stderr]).to match(/Deleting app '#{first_app}'[.]+? done!/)
      expect(result[:stderr]).to match(/Deleting image '#{first_app}:1'[.]+? done!/)
      expect(result[:stderr]).to match(/Deleting app '#{second_app}'[.]+? done!/)
      expect(result[:stderr]).to match(/Deleting image '#{second_app}:1'[.]+? done!/)
    end
  end
end
