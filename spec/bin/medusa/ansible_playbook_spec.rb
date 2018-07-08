RSpec.describe 'medusa ansible-playbook', type: :bash, docker: true, ansible: true do
  subject { medusa_script }

  it 'works' do
    expect(run_script(subject, ['ansible-playbook', '--help'])).to be true
    expect(subject.stdout).to include('Usage: ansible-playbook')
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

  describe 'MEDUSA_SETTINGS_FILE' do
    it 'passes that file as --extra-vars if it exists' do
      File.write(settings_file, {
        "my_override" => 100
      }.to_yaml)

      expect(
        run_script(subject, ['ansible-playbook', './settings_test.yml'])
      ).to be true

      expect(subject.stdout).to include('"my_override": 100')
    end

    it 'accepts an override' do
      File.write('some other file.yml', {
        "my_override" => 100
      }.to_yaml)

      expect(
        run_script(subject, ['ansible-playbook', './settings_test.yml'], env: {
          "MEDUSA_SETTINGS_FILE" => 'some other file.yml'
        })
      ).to be true

      expect(subject.stdout).to include('"my_override": 100')
    end
  end

  describe 'MEDUSA_DOCKERHOST' do
    it 'accepts an override' do
      expect(
        run_script(subject, ['ansible-playbook', './dockerhost_test.yml'], env: {
          "MEDUSA_DOCKERHOST" => 'blah.blah'
        })
      ).to be true

      expect(subject.stdout).to include('"dockerhost": "blah.blah"')
    end
  end

  describe 'ANSIBLE_CONFIG' do
    it 'infers it from the specified playbook path' do
      expect(
        run_script(subject, ['ansible-playbook', './ansible_cfg_test/playbook.yml'])
      ).to be true

      # expect(subject.stdout).to include('"dockerhost": "blah.blah"')
    end
  end
end