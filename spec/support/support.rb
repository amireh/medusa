module Support
  ROOT_DIR = File.expand_path("../../../", __FILE__).freeze
  FIXTURE_DIR = File.expand_path("../../../spec/fixture", __FILE__).freeze
  TEMP_DIR = File.expand_path("../../../tmp/junk", __FILE__).freeze

  def medusa_script
    a_script "exec '#{File.join(Support::ROOT_DIR, 'bin/medusa')}' \"$@\""
  end

  def tmp_path(name)
    File.join(TEMP_DIR, "#{name}")
  end

  def create_file(path, contents)
    tmp_path(path).tap do |filepath|
      FileUtils.mkdir_p(File.dirname(filepath))

      File.write(filepath, contents)
    end
  end
end
