# frozen_string_literal: true

require "spec_helper"

describe Command::Open do
  it "raises error if workload does not exist" do
    app = dummy_test_app

    run_command("apply-template", "gvc", "-a", app)
    result = run_command("open", "-a", app)
    run_command("delete", "-a", app, "--yes")

    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Can't find workload 'rails'")
  end

  context "when workload exists" do
    let(:app) { dummy_test_app }

    before do
      run_command("apply-template", "gvc", "rails", "redis", "-a", app)
    end

    after do
      run_command("delete", "-a", app, "--yes")
    end

    it "opens endpoint of default workload" do
      allow(Kernel).to receive(:exec)

      app = dummy_test_app

      run_command("open", "-a", app)

      expected_url = %r{https://rails-.+?.cpln.app}
      expect(Kernel).to have_received(:exec).with(match(expected_url))
    end

    it "opens endpoint of specific workload" do
      allow(Kernel).to receive(:exec)

      app = dummy_test_app

      run_command("open", "-a", app, "--workload", "redis")

      expected_url = %r{https://redis-.+?.cpln.app}
      expect(Kernel).to have_received(:exec).with(match(expected_url))
    end
  end
end
