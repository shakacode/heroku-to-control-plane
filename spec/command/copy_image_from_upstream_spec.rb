# frozen_string_literal: true

require "spec_helper"

describe Command::CopyImageFromUpstream do
  it "raises error if Docker is not running" do
    allow(Shell).to receive(:cmd).and_return({ success: false })

    app = dummy_test_app

    result = run_command("copy-image-from-upstream", "-a", app, "--upstream-token", "token")

    expect(Shell).to have_received(:cmd).with(include("docker version")).once
    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Can't run Docker")
  end

  it "raises error if 'upstream' is not defined" do
    app = dummy_test_app("with-nothing")

    result = run_command("copy-image-from-upstream", "-a", app, "--upstream-token", "token")

    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Can't find option 'upstream'")
  end

  it "raises error if upstream app is not defined" do
    app = dummy_test_app("with-undefined-upstream")

    result = run_command("copy-image-from-upstream", "-a", app, "--upstream-token", "token")

    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Can't find option 'cpln_org' for app 'undefined'")
  end

  it "raises error if 'cpln_org' is not defined for upstream app" do
    upstream_app = dummy_test_app("without-org")
    app = dummy_test_app

    ENV["CPLN_UPSTREAM"] = upstream_app

    result = run_command("copy-image-from-upstream", "-a", app, "--upstream-token", "token")

    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Can't find option 'cpln_org' for app '#{upstream_app}'")
  end

  it "fails to fetch upstream image URL if using invalid token for upstream org" do
    upstream_app = dummy_test_app("with-different-org")
    app = dummy_test_app

    ENV["CPLN_UPSTREAM"] = upstream_app

    run_command("apply-template", "gvc", "-a", upstream_app)
    run_command("apply-template", "gvc", "-a", app)
    run_command("build-image", "-a", upstream_app)
    result = run_command("copy-image-from-upstream", "-a", app, "--upstream-token", "token")
    run_command("delete", "-a", upstream_app, "--yes")
    run_command("delete", "-a", app, "--yes")

    expect(result[:stderr]).to match(/Fetching upstream image URL[.]+? failed!/)
  end

  context "when using valid token for upstream org" do
    let(:token) { `cpln profile token default`.strip }
    let(:upstream_app) { dummy_test_app("with-different-org") }
    let(:app) { dummy_test_app }

    before do
      ENV["CPLN_UPSTREAM"] = upstream_app

      run_command("apply-template", "gvc", "-a", upstream_app)
      run_command("apply-template", "gvc", "-a", app)
    end

    after do
      run_command("delete", "-a", upstream_app, "--yes")
      run_command("delete", "-a", app, "--yes")
    end

    it "copies latest image from upstream" do
      # Simulates looping through generated profile names to avoid conflicts
      allow_any_instance_of(Controlplane).to receive(:profile_exists?).and_return(true, false) # rubocop:disable RSpec/AnyInstance

      run_command("build-image", "-a", upstream_app)
      result = run_command("copy-image-from-upstream", "-a", app, "--upstream-token", token)

      expect(result[:stderr]).to match(%r{Pulling image from '.+?/#{upstream_app}:1'})
      expect(result[:stderr]).to match(%r{Pushing image to '.+?/#{app}:1'})
    end

    it "copies latest image from upstream along with commit hash" do
      run_command("build-image", "-a", upstream_app, "--commit", "abc123")
      result = run_command("copy-image-from-upstream", "-a", app, "--upstream-token", token)

      expect(result[:stderr]).to match(%r{Pulling image from '.+?/#{upstream_app}:1_abc123'})
      expect(result[:stderr]).to match(%r{Pushing image to '.+?/#{app}:1_abc123'})
    end

    it "copies specific image from upstream" do
      run_command("build-image", "-a", upstream_app)
      run_command("build-image", "-a", upstream_app)
      result = run_command("copy-image-from-upstream", "-a", app, "--upstream-token", token,
                           "--image", "#{upstream_app}:1")

      expect(result[:stderr]).to match(%r{Pulling image from '.+?/#{upstream_app}:1'})
      expect(result[:stderr]).to match(%r{Pushing image to '.+?/#{app}:1'})
    end
  end
end
