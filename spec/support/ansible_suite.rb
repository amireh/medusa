require_relative './support'

module AnsibleSuite
  SETTINGS_FILE = "#{Support::FIXTURE_DIR}/settings.yml".freeze

  def settings_file()
    SETTINGS_FILE
  end

  def self.configure(config)
    config.around(:each, ansible: true) do |example|
      Dir.chdir Support::FIXTURE_DIR do
        example.call
      end
    end

    config.after(:each, ansible: true) do
      FileUtils.rm(SETTINGS_FILE) if File.exist?(SETTINGS_FILE)
    end
  end
end