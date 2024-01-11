# frozen_string_literal: true

require "spec_helper"

describe Command::OpenConsole do
  it "opens app console on Control Plane" do
    allow(Kernel).to receive(:exec)

    app = dummy_test_app

    run_command("open-console", "-a", app)

    expected_url = %r{https://console.cpln.io/console/org/.+?/gvc/#{app}/-info}
    expect(Kernel).to have_received(:exec).with(match(expected_url))
  end

  it "opens workload page on Control Plane" do
    allow(Kernel).to receive(:exec)

    app = dummy_test_app

    run_command("open-console", "-a", app, "--workload", "rails")

    expected_url = %r{https://console.cpln.io/console/org/.+?/gvc/#{app}/workload/rails/-info}
    expect(Kernel).to have_received(:exec).with(match(expected_url))
  end
end
