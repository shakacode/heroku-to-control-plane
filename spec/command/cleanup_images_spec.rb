# frozen_string_literal: true

require "spec_helper"

describe Command::CleanupImages do
  it "raises error if 'image_retention_max_qty' or 'image_retention_days' are not defined" do
    app = dummy_test_app("with-nothing")

    result = run_command("cleanup-images", "-a", app)

    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Can't find either option 'image_retention_max_qty' or 'image_retention_days'")
  end

  it "displays message if there are no images to delete" do
    app = dummy_test_app

    result = run_command("cleanup-images", "-a", app)

    expect(result[:stderr]).to include("No images to delete")
  end

  context "when there are images to delete" do
    it "lists images based on max quantity" do
      allow(Shell).to receive(:confirm).and_return(false)

      app = dummy_test_app("with-image-retention-max-qty")

      run_command("apply-template", "gvc", "-a", app)
      # Excess image, will be listed
      run_command("build-image", "-a", app)
      # Images that don't exceed max quantity of 3, won't be listed
      run_command("build-image", "-a", app)
      run_command("build-image", "-a", app)
      run_command("build-image", "-a", app)
      # Latest image, excluded from quantity calculation, won't be listed
      run_command("build-image", "-a", app)
      result = run_command("cleanup-images", "-a", app)
      run_command("delete", "-a", app, "--yes")

      expect(Shell).to have_received(:confirm).with(include("1 images")).once
      expect(result[:stderr]).to match(/#{app}:1 \(.+? - exceeds max quantity of 3\)/)
    end

    it "lists images based on days" do
      allow(Shell).to receive(:confirm).and_return(false)

      app = dummy_test_app("with-image-retention-days")

      run_command("apply-template", "gvc", "-a", app)
      # Old image, will be listed
      run_command("build-image", "-a", app)
      # Latest image, excluded from days calculation, won't be listed
      run_command("build-image", "-a", app)
      travel_to_days_later(30)
      result = run_command("cleanup-images", "-a", app)
      travel_back
      run_command("delete", "-a", app, "--yes")

      expect(Shell).to have_received(:confirm).with(include("1 images")).once
      expect(result[:stderr]).to match(/#{app}:1 \(.+? - older than 30 days\)/)
    end

    it "only lists images from exact app" do
      allow(Shell).to receive(:confirm).and_return(false)

      target_app = dummy_test_app
      another_app = dummy_test_app

      run_command("apply-template", "gvc", "-a", target_app)
      run_command("apply-template", "gvc", "-a", another_app)
      # Old image from target app, will be listed
      run_command("build-image", "-a", target_app)
      # Latest image from target app, won't be listed
      run_command("build-image", "-a", target_app)
      # Images from another app, won't be listed
      run_command("build-image", "-a", another_app)
      run_command("build-image", "-a", another_app)
      travel_to_days_later(30)
      result = run_command("cleanup-images", "-a", target_app)
      travel_back
      run_command("delete", "-a", target_app, "--yes")
      run_command("delete", "-a", another_app, "--yes")

      expect(Shell).to have_received(:confirm).with(include("1 images")).once
      expect(result[:stderr]).to match(/#{target_app}:1 \(.+? - older than 30 days\)/)
    end

    it "lists images from all matching apps" do
      allow(Shell).to receive(:confirm).and_return(false)

      first_app = dummy_test_app
      second_app = dummy_test_app

      run_command("apply-template", "gvc", "-a", first_app)
      run_command("apply-template", "gvc", "-a", second_app)
      # Old image from first app, will be listed
      run_command("build-image", "-a", first_app)
      # Latest image from first app, won't be listed
      run_command("build-image", "-a", first_app)
      # Old image from second app, will be listed
      run_command("build-image", "-a", second_app)
      # Latest image from second app, won't be listed
      run_command("build-image", "-a", second_app)
      travel_to_days_later(30)
      result = run_command("cleanup-images", "-a", CommandHelpers::DUMMY_TEST_APP_PREFIX)
      travel_back
      run_command("delete", "-a", first_app, "--yes")
      run_command("delete", "-a", second_app, "--yes")

      expect(Shell).to have_received(:confirm).with(include("2 images")).once
      expect(result[:stderr]).to match(/#{first_app}:1 \(.+? - older than 30 days\)/)
      expect(result[:stderr]).to match(/#{second_app}:1 \(.+? - older than 30 days\)/)
    end

    it "asks for confirmation and deletes images" do
      allow(Shell).to receive(:confirm).and_return(true)

      app = dummy_test_app

      run_command("build-image", "-a", app)
      travel_to_days_later(30)
      result = run_command("cleanup-images", "-a", app)
      travel_back

      expect(Shell).to have_received(:confirm).with(include("1 images")).once
      expect(result[:stderr]).to match(/Deleting image '#{app}:1'[.]+? done!/)
    end

    it "skips confirmation and deletes images" do
      allow(Shell).to receive(:confirm).and_return(false)

      app = dummy_test_app

      run_command("build-image", "-a", app)
      travel_to_days_later(30)
      result = run_command("cleanup-images", "-a", app, "--yes")
      travel_back

      expect(Shell).not_to have_received(:confirm)
      expect(result[:stderr]).to match(/Deleting image '#{app}:1'[.]+? done!/)
    end
  end
end
