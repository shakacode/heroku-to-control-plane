# frozen_string_literal: true

module DummyAppSetup
  def self.setup
    ENV["CONFIG_FILE_PATH"] = "#{spec_directory}/dummy/.controlplane/controlplane.yml"
  end

  def self.spec_directory
    current_file_path = File.expand_path(__FILE__)
    current_directory = File.dirname(current_file_path)
    File.dirname(current_directory)
  end
end
