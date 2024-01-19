# frozen_string_literal: true

require "spec_helper"

describe Command::Ps do
  it "raises error if any of the workloads does not exist" do
    app = dummy_test_app

    run_command("apply-template", "gvc", "-a", app)
    result = run_command("ps", "-a", app)
    run_command("delete", "-a", app, "--yes")

    expect(result[:status]).to be(1)
    expect(result[:stderr]).to include("Can't find workload 'rails'")
  end

  context "when workloads exist" do
    it "displays nothing if no replicas are running" do
      app = dummy_test_app

      run_command("apply-template", "gvc", "rails", "redis", "postgres", "-a", app)
      run_command("build-image", "-a", app)
      run_command("deploy-image", "-a", app)
      result = run_command("ps", "-a", app)
      run_command("delete", "-a", app, "--yes")

      expect(result[:stdout]).to be_empty
    end

    context "when replicas are running" do
      let(:app) { dummy_test_app }

      before do
        run_command("apply-template", "gvc", "rails", "redis", "postgres", "-a", app)
        run_command("build-image", "-a", app)
        run_command("deploy-image", "-a", app)
        run_command("ps:start", "-a", app, "--wait")
      end

      after do
        run_command("delete", "-a", app, "--yes")
      end

      it "displays currently running replicas for all workloads" do
        result = run_command("ps", "-a", app)

        expect(result[:stdout]).to include("rails-")
        expect(result[:stdout]).to include("redis-")
        expect(result[:stdout]).to include("postgres-")
      end

      it "displays currently running replicas for specific workload" do
        result = run_command("ps", "-a", app, "--workload", "rails")

        expect(result[:stdout]).to include("rails-")
        expect(result[:stdout]).not_to include("redis-")
        expect(result[:stdout]).not_to include("postgres-")
      end
    end
  end
end
