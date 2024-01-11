# frozen_string_literal: true

require "spec_helper"

describe Command::Version do
  it "displays version" do
    result = run_command("--version")

    expect(result[:stdout]).to include(Cpl::VERSION)
  end
end
