# frozen_string_literal: true

require "spec_helper"

describe Command::NoCommand do
  it "displays help when called with nothing" do
    result = run_command

    expect(result[:stdout]).to include("cpl commands")
  end

  it "displays version when called with --version" do
    result = run_command("--version")

    expect(result[:stdout]).to include(Cpl::VERSION)
  end
end
