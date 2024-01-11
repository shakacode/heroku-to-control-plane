# frozen_string_literal: true

require "spec_helper"

describe Command::Exists do
  it "exits with 0 if app exists" do
    app = dummy_test_app

    run_command("apply-template", "gvc", "-a", app)
    result = run_command("exists", "-a", app)
    run_command("delete", "-a", app, "--yes")

    expect(result[:status]).to be(0)
  end

  it "exits with 1 if app does not exist" do
    app = dummy_test_app

    result = run_command("exists", "-a", app)

    expect(result[:status]).to be(1)
  end
end
