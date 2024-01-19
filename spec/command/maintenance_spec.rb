# frozen_string_literal: true

require "spec_helper"

describe Command::Maintenance do
  it "raises error if app has no domain" do
    app = dummy_test_app("with-nothing")

    result = run_command("maintenance", "-a", app)

    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Can't find domain")
  end

  context "when app has domain" do
    let(:app) { dummy_test_app }

    before do
      run_command("apply-template", "gvc", "rails", "redis", "postgres", "maintenance", "-a", app)
      run_command("build-image", "-a", app)
      run_command("deploy-image", "-a", app)
      run_command("ps:start", "-a", app, "--wait")
    end

    after do
      run_command("delete", "-a", app, "--yes")
    end

    it "displays 'on' if maintenance mode is enabled" do
      allow(Kernel).to receive(:sleep)

      run_command("maintenance:on", "-a", app)
      result = run_command("maintenance", "-a", app)

      expect(result[:stdout]).to include("on")
    end

    it "displays 'off' if maintenance mode is disabled" do
      allow(Kernel).to receive(:sleep)

      result = run_command("maintenance", "-a", app)

      expect(result[:stdout]).to include("off")
    end

    it "displays 'off' if maintenance mode is enabled and then disabled" do
      allow(Kernel).to receive(:sleep)

      run_command("maintenance:on", "-a", app)
      run_command("maintenance:off", "-a", app)
      result = run_command("maintenance", "-a", app)

      expect(result[:stdout]).to include("off")
    end
  end
end
