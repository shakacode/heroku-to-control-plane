# frozen_string_literal: true

require "spec_helper"

describe Command::BuildImage do
  it "raises error if Docker is not running" do
    allow(Shell).to receive(:cmd).and_return({ success: false })

    app = dummy_test_app

    result = run_command("build-image", "-a", app)

    expect(Shell).to have_received(:cmd).with(include("docker version")).once
    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Can't run Docker")
  end

  it "raises error if Dockerfile does not exist" do
    app = dummy_test_app("with-unexistent-dockerfile")

    result = run_command("build-image", "-a", app)

    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Can't find Dockerfile")
  end

  context "when Dockerfile exists" do
    let(:app) { dummy_test_app }

    before do
      run_command("apply-template", "gvc", "-a", app)
    end

    after do
      run_command("delete", "-a", app, "--yes")
    end

    it "builds and pushes image" do
      result = run_command("build-image", "-a", app)

      expect(result[:stderr]).to match(%r{Pushed image to '/org/.+?/image/#{app}:1'})
    end

    it "builds and pushes image with commit hash" do
      result = run_command("build-image", "-a", app, "--commit", "abc123")

      expect(result[:stderr]).to match(%r{Pushed image to '/org/.+?/image/#{app}:1_abc123'})
    end

    it "subsequent builds increase image number" do
      first_build_result = run_command("build-image", "-a", app)
      second_build_result = run_command("build-image", "-a", app)

      expect(first_build_result[:stderr]).to match(%r{Pushed image to '/org/.+?/image/#{app}:1'})
      expect(second_build_result[:stderr]).to match(%r{Pushed image to '/org/.+?/image/#{app}:2'})
    end
  end
end
