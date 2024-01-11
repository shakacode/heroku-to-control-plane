# frozen_string_literal: true

require "spec_helper"

describe Command::ApplyTemplate do
  it "raises error if any of the templates does not exist" do
    app = dummy_test_app

    result = run_command("apply-template", "gvc", "rails", "unexistent", "-a", app)

    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Missing templates")
    expect(result[:stderr]).to include("unexistent")
  end

  context "when app already exists" do
    let(:app) { dummy_test_app }

    before do
      run_command("apply-template", "gvc", "-a", app)
    end

    after do
      run_command("delete", "-a", app, "--yes")
    end

    it "asks for confirmation and does nothing" do
      allow(Shell).to receive(:confirm).and_return(false)

      result = run_command("apply-template", "gvc", "-a", app)

      expect(Shell).to have_received(:confirm).with(include("App '#{app}' already exists")).once
      expect(result[:stderr]).to include("Skipped templates")
      expect(result[:stderr]).to include("gvc")
    end

    it "asks for confirmation and re-creates app" do
      allow(Shell).to receive(:confirm).and_return(true)

      result = run_command("apply-template", "gvc", "-a", app)

      expect(Shell).to have_received(:confirm).with(include("App '#{app}' already exists")).once
      expect(result[:stderr]).to include("Created items")
      expect(result[:stderr]).to include("[app] #{app}")
    end

    it "skips confirmation and re-creates app" do
      allow(Shell).to receive(:confirm).and_return(false)

      result = run_command("apply-template", "gvc", "-a", app, "--yes")

      expect(Shell).not_to have_received(:confirm)
      expect(result[:stderr]).to include("Created items")
      expect(result[:stderr]).to include("[app] #{app}")
    end
  end

  context "when workload already exists" do
    let(:app) { dummy_test_app }

    before do
      run_command("apply-template", "gvc", "rails", "-a", app)
    end

    after do
      run_command("delete", "-a", app, "--yes")
    end

    it "asks for confirmation and does nothing" do
      allow(Shell).to receive(:confirm).and_return(false)

      result = run_command("apply-template", "rails", "-a", app)

      expect(Shell).to have_received(:confirm).with(include("Workload 'rails' already exists")).once
      expect(result[:stderr]).to include("Skipped templates")
      expect(result[:stderr]).to include("rails")
    end

    it "asks for confirmation and re-creates workload" do
      allow(Shell).to receive(:confirm).and_return(true)

      result = run_command("apply-template", "rails", "-a", app)

      expect(Shell).to have_received(:confirm).with(include("Workload 'rails' already exists")).once
      expect(result[:stderr]).to include("Created items")
      expect(result[:stderr]).to include("[workload] rails")
    end

    it "skips confirmation and re-creates workload" do
      allow(Shell).to receive(:confirm).and_return(false)

      result = run_command("apply-template", "rails", "-a", app, "--yes")

      expect(Shell).not_to have_received(:confirm)
      expect(result[:stderr]).to include("Created items")
      expect(result[:stderr]).to include("[workload] rails")
    end
  end

  it "applies valid templates and fails to apply invalid templates" do
    app = dummy_test_app

    result = run_command("apply-template", "gvc", "rails", "invalid", "-a", app)
    run_command("delete", "-a", app, "--yes")

    expect(result[:stderr]).to include("Created items")
    expect(result[:stderr]).to include("[app] #{app}")
    expect(result[:stderr]).to include("[identity] #{app}-identity")
    expect(result[:stderr]).to include("[workload] rails")
    expect(result[:stderr]).to include("Failed to apply templates")
    expect(result[:stderr]).to include("invalid")
  end
end
