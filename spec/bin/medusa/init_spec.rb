RSpec.describe 'medusa init', type: :bash do
  let(:root) { Support::ROOT_DIR }

  subject { medusa_script }

  it 'prints instructions' do
    run_script(subject, ['init'])

    expect(subject.stderr).to include('# Load medusa by appending')
    expect(subject.stdout).to be_empty
  end

  it 'exits with 1' do
    expect(run_script(subject, ['init'])).to be false
  end

  context 'with "-" for an arg' do
    it 'adjusts the PATH' do
      run_script(subject, ['init', '-'])
      expect(subject.stdout).to include("export PATH=\"#{root}/bin:${PATH}\"")
    end

    it 'sources the completion script' do
      run_script(subject, ['init', '-'])
      expect(subject.stdout).to include("source '#{root}/completions/medusa.bash'")
    end

    it 'exits with 0' do
      expect(run_script(subject, ['init', '-'])).to be true
    end
  end
end