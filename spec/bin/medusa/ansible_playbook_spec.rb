require 'yaml'

RSpec.describe 'medusa ansible-playbook', type: :bash, docker: true do
  let(:root) { Support::ROOT_DIR }
  let(:fixture_dir) { Support::FIXTURE_DIR }

  subject { a_script "exec '#{File.join(root, 'bin/medusa')}' \"$@\"" }

  around(:each) do |example|
    Dir.chdir fixture_dir do
      example.call
    end
  end

  it 'works' do
    expect(run_script(subject, ['ansible-playbook', '--help'])).to be true
    expect(subject.stdout).to include('Usage: ansible-playbook')
  end

  it "exposes env vars" do
    env = {
      "ANSIBLE_CONFIG" => "/blah.cfg",
      "ANSIBLE_GATHERING" => "implicit",
      "ANSIBLE_RETRY_FILES_ENABLED" => "true",
      "ANSIBLE_STDERR_CALLBACK" => "minimal",
      "ANSIBLE_STDOUT_CALLBACK" => "minimal"
    }

    expect(
      run_script(subject, ['ansible-playbook', './env_test.yml'], env: env)
    ).to be true

    env.each do |key, value|
      expect(subject.stdout).to include("#{key}=#{value}")
    end
  end

  it "utilizes ANSIBLE_VAULT_PASS" do
    env = {
      "ANSIBLE_VAULT_PASS" => "some secret", # must match what used to encrypt_string the content
      "ANSIBLE_STDOUT_CALLBACK" => "minimal"
    }

    expect(
      run_script(subject, ['ansible-playbook', './vault_test.yml'], env: env)
    ).to be true

    expect(subject.stdout).to include('"secret_var": "foo"')
  end

  it "mounts the medusa library at /mnt/medusa" do
    expect(
      run_script(subject, ['ansible-playbook', './medusa_lib_test.yml'])
    ).to be true
  end

  describe 'vars/medusa.yml' do
    it 'exposes docker host related variables' do
      expect(
        run_script(subject, ['ansible-playbook', './dockerhost_test.yml'])
      ).to be true

      expect(subject.stdout).to match(/"dockerhost": ".+"/),
        '{{ dockerhost }} => the docker host ip address'

      expect(subject.stdout).to match(/"dockerhost_uid": "#{`id -u`.strip}"/),
        '{{ dockerhost_uid }} => the docker host user uid'

      expect(subject.stdout).to match(/"dockerhost_gid": "#{`id -g`.strip}"/),
        '{{ dockerhost_gid }} => the docker host **primary** gid'

      expect(subject.stdout).to match(/"dockerhost_user": "donkey"/),
        '{{ dockerhost_user }} => literal "donkey"'

      expect(subject.stdout).to match(/"dockerhost_group": "donkey"/),
        '{{ dockerhost_group }} => literal "donkey"'
    end
  end

  describe 'settings.yml' do
    let(:settings_file) { "#{fixture_dir}/settings.yml" }

    after(:each) do
      FileUtils.rm(settings_file) if File.exist?(settings_file)
    end

    it 'passes that file as --extra-vars if it exists' do
      File.write(settings_file, {
        "my_override" => 100
      }.to_yaml)

      expect(
        run_script(subject, ['ansible-playbook', './settings_test.yml'])
      ).to be true

      expect(subject.stdout).to include('"my_override": 100')
    end
  end
end