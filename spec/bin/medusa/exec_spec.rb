require 'yaml'

RSpec.describe 'medusa exec', type: :bash, ansible: true do
  subject { medusa_script }

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
end