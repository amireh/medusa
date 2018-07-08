require 'yaml'

RSpec.describe 'medusa', type: :bash do
  let(:root) { Support::ROOT_DIR }

  subject {
    a_script File.read(File.join(root, 'bin/medusa'))
  }

  it 'works' do
    run_script(subject, ['help'])

    expect(subject.exit_code).to eq(0)
    expect(subject.stdout).to include('medusa')
  end

  describe '.ansible-galaxy' do
    it 'works', docker: true do
      expect(run_script(subject, ['ansible-galaxy', '--help'])).to be true
      expect(subject.stdout).to include('Usage: ansible-galaxy')
    end
  end

  describe '.ansible-vault' do
    it 'works', docker: true do
      expect(run_script(subject, ['ansible-vault', '--help'])).to be true
      expect(subject.stdout).to include('Usage: ansible-vault')
    end
  end

  describe '.exec', docker: true do
    it 'works' do
      expect(run_script(subject, ['exec', 'whoami'])).to be true
      expect(subject.stdout).to include('root')
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
  end

  describe 'MEDUSA_SSH_DIR', docker: true do
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

  describe '.encrypt-file / .decrypt-file' do
    let(:file) { tmp_path('foo') }

    it 'works', docker: true do
      File.write(file, 'hi')

      expect {
        run_script(subject, ['ansible-vault', 'encrypt', './tmp/junk/foo'], {
          env: { 'ANSIBLE_VAULT_PASS' => 'some pass' }
        })
      }.to change {
        File.read(file)
      }.from('hi')

      expect {
        run_script(subject, ['ansible-vault', 'decrypt', './tmp/junk/foo'], {
          env: { 'ANSIBLE_VAULT_PASS' => 'some pass' }
        })
      }.to change {
        File.read(file)
      }.to('hi')
    end
  end

  describe '.encrypt-string' do
    it 'works', docker: true do
      expect(run_script(subject, ['ansible-vault', 'encrypt_string', 'foo'], {
        env: { 'ANSIBLE_VAULT_PASS' => 'some pass' }
      })).to be true

      expect(subject.stdout).to include('!vault')
    end
  end

  describe '.info' do
    subject { File.join(root, 'bin/medusa') }

    it 'works' do
      output = `#{subject} info`

      expect(output).to include("MEDUSA_DIR=#{root}")
      expect(output).to include("MEDUSA_BIN=#{File.join(root, 'bin/medusa')}")
    end
  end

  describe '.init' do
    subject { File.join(root, 'bin/medusa') }

    it 'prints instructions' do
      stdout = `#{subject} init 2>&1`
      expect(stdout).to include('# Load medusa automatically by')
    end

    it 'exits with 1' do
      expect(system("#{subject} init 2>/dev/null")).to be false
    end

    context 'with "-" for an arg' do
      let(:stdout) { `#{subject} init -` }

      it 'adjusts the PATH' do
        expect(stdout).to include("export PATH=\"#{root}/bin:${PATH}\"")
      end

      it 'sources the completion script' do
        expect(stdout).to include("source '#{root}/completions/medusa.bash'")
      end

      it 'exits with 0' do
        expect(system("#{subject} init - >/dev/null")).to be true
      end
    end
  end
end