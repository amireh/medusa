RSpec.describe 'medusa exec', type: :bash, docker: true, ansible: true do
  subject { medusa_script }

  it 'works' do
    expect(run_script(subject, ['exec', 'whoami'])).to be true
    expect(subject.stdout).to include('root')
  end

  it "exposes env vars" do
    env = {
      "ANSIBLE_CONFIG" => "/blah.cfg",
      "ANSIBLE_RETRY_FILES_ENABLED" => "true",
      "ANSIBLE_STDERR_CALLBACK" => "minimal",
      "ANSIBLE_STDOUT_CALLBACK" => "minimal",
      "ANSIBLE_FOO_BAR" => "baz"
    }

    expect(
      run_script(subject, ['ansible-playbook', './env_test.yml'], env: env)
    ).to be true

    env.each do |key, value|
      expect(subject.stdout).to include("#{key}=#{value}")
    end
  end

  it 'mimics my UID' do
    run_script(subject, ['exec', 'mimic', 'id', '-u'])

    expect(subject.stdout.strip).to eq(`id -u`.strip)
  end

  it 'mimics my primary GID' do
    run_script(subject, ['exec', 'mimic', 'id', '-g'])

    expect(subject.stdout.strip).to eq(`id -g`.strip)
  end

  it 'mimics my GIDs' do
    run_script(subject, ['exec', 'mimic', 'id', '-G'])

    expect(subject.stdout.strip).to eq(`id -G`.strip)
  end

  describe 'MEDUSA_SSH_DIR' do
    it 'is a no-op if ssh dir does not exist' do
      expect(run_script(subject, [ 'exec', 'true' ], env: {
        "MEDUSA_SSH_DIR" => "/foo/bar/baz/kljaxhcvlyuioadf"
      })).to be true
    end

    it 'mounts an .ssh directory if found' do
      FileUtils.mkdir(tmp_path('some-folder'))

      expect(run_script(subject, [ 'exec', 'true' ], env: {
        "MEDUSA_SSH_DIR" => "#{tmp_path('some-folder')}"
      })).to be true
    end

    it 'mounts an .ssh directory containing spaces if found' do
      FileUtils.mkdir(tmp_path('some folder'))

      expect(run_script(subject, [ 'exec', 'true' ], env: {
        "MEDUSA_SSH_DIR" => "#{tmp_path('some folder')}"
      })).to be true
    end
  end

  describe 'MEDUSA_VERBOSE' do
    it 'prints the docker run command' do
      expect(run_script(subject, [ 'exec', 'true' ], env: {
        "MEDUSA_VERBOSE" => "1"
      })).to be true

      expect(subject.stderr).to match(/^docker run .+ true$/)
    end
  end

  describe 'MEDUSA_CONTAINER' do
    it 'prints the docker run command' do
      expect(run_script(subject, [ 'exec',
        'sh', '-c', "docker inspect $(hostname) -f '{{ .Name }}'"
      ], env: {
        "MEDUSA_CONTAINER" => "meme"
      })).to be true

      expect(subject.stdout.strip).to eq '/meme'
    end
  end
end