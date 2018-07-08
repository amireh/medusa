RSpec.describe 'medusa-installer', type: :bash do
  subject {
    a_script File.read('medusa-installer')
  }

  def bind(fn)
    a_script File.read('medusa-installer').sub('main "$@"', "#{fn} \"$@\"")
  end

  it 'bails if "git" is not installed' do
    expect(subject).to receive(:type).with_args('-p git').and_return(1)
    expect(run_script(subject)).to be false
    expect(subject.stderr).to include('git is required')
  end

  it 'works' do
    run_script(subject, env: {
      "BASH_PROFILE" => "#{create_file('.bashrc', '')}",
      "MEDUSA_DIR" => "#{tmp_path('.medusa')}",
      "MEDUSA_SRC" => "#{Support::ROOT_DIR}/.git"
    })

    expect(subject.exit_code).to eq(0)
  end

  describe 'installation' do
    subject { bind('installer.install_medusa') }

    let(:env) { {
      "BASH_PROFILE" => "#{create_file('.bashrc', '')}",
      "MEDUSA_DIR" => "#{tmp_path('.medusa')}",
      "MEDUSA_SRC" => "#{Support::ROOT_DIR}/.git"
    } }

    def git(cmd, path: tmp_path('.medusa'))
      `cd #{path} && git #{cmd}`.strip
    end

    it 'works if directory does not exist' do
      expect {
        run_script(subject, env: env)
      }.to change {
        File.exist?(tmp_path('.medusa/.git'))
      }.from(false).to(true)
    end

    it 'works if the directory already exists' do
      FileUtils.mkdir_p(tmp_path('.medusa'))
      expect(run_script(subject, env: env)).to be true
    end

    it 'works if the repository already exists' do
      system <<-EOF
        cd #{tmp_path('')} &&
        git clone --quiet #{env['MEDUSA_SRC']} .medusa
      EOF

      expect(run_script(subject, env: env)).to be true
    end

    it 'rewires the origin' do
      system <<-EOF
        cd #{tmp_path('')} &&
        git clone --quiet #{env['MEDUSA_SRC']} .medusa &&
        cd .medusa &&
        git remote set-url origin foo/bar
      EOF

      expect {
        run_script(subject, env: env)
      }.to change {
        git('remote -v | grep origin').include?('foo/bar')
      }.from(true).to(false)
    end

    it 'works if on the master branch already' do
      system <<-EOF
        cd #{tmp_path('')} &&
        git clone --quiet #{env['MEDUSA_SRC']} .medusa &&
        cd .medusa &&
        git checkout --quiet master
      EOF

      expect(run_script(subject, env: env)).to be true
    end

    it 'checks out the master branch if on a different one' do
      system <<-EOF
        cd #{tmp_path('')} &&
        git clone --quiet #{env['MEDUSA_SRC']} .medusa &&
        cd .medusa &&
        git checkout --quiet -b other
      EOF

      expect {
        expect(run_script(subject, env: env)).to be true
      }.to change {
        git('rev-parse --abbrev-ref HEAD')
      }.from('other').to('master')
    end

    it 'bails if a git clone fails' do
      expect(run_script(subject, env: env.merge({
        "MEDUSA_SRC" => 'askldjflaskdjf laskdf'
      }))).to be false
    end
  end

  describe 'configure_bash' do
    subject { bind('installer.configure_bash') }

    let(:env) { {
      "BASH_PROFILE" => "#{create_file('.bashrc', '')}",
      "MEDUSA_DIR" => "#{tmp_path('.medusa')}",
      "MEDUSA_BIN" => "medusa",
      "MEDUSA_SRC" => "#{Support::ROOT_DIR}/.git"
    } }

    let(:eval_snippet) { "eval \"$('#{env['MEDUSA_BIN']}' init -)\"" }

    let(:installer_stamp) { '# Automatically added by medusa-installer' }

    it "complains if it can't find the profile" do
      expect(run_script(subject, env: env.merge({
        "BASH_PROFILE" => "kjhasdfk zxkl vhzxlcj "
      }))).to be false

      expect(subject.stdout).to include('Unable to locate Bash profile')
    end

    it "evals the output of 'medusa init -' in bashrc" do
      expect(subject).to receive(:type)
        .with_args('-p git').and_return(0)
        .with_args('-p medusa').and_return(1)

      expect(run_script(subject, env: env)).to be true
      expect(File.read(env['BASH_PROFILE'])).to include(eval_snippet)
      expect(subject.stdout).to include 'Bash configured.'
    end

    it "does not bork the current content of bashrc" do
      File.write env['BASH_PROFILE'], <<-EOF
        hello
        world
      EOF

      expect {
        run_script(subject, env: env)
      }.not_to change {
        File.read(env['BASH_PROFILE']).include?('hello') &&
        File.read(env['BASH_PROFILE']).include?('world')
      }
    end
  end
end