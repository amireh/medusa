RSpec.describe 'medusa ansible-vault', type: :bash, docker: true do
  subject { medusa_script }

  it 'works' do
    expect(run_script(subject, ['ansible-vault', '--help'])).to be true
    expect(subject.stdout).to include('Usage: ansible-vault ')
  end

  describe '.encrypt-file / .decrypt-file' do
    let(:file) { 'secret_var.txt' }

    it 'works', ansible: true do
      contents = File.read(file)

      expect {
        run_script(subject, ['ansible-vault', 'encrypt', 'secret_var.txt'], {
          env: { 'ANSIBLE_VAULT_PASS' => 'some pass' }
        })
      }.to change {
        File.read(file)
      }.from(contents)

      expect {
        run_script(subject, ['ansible-vault', 'decrypt', 'secret_var.txt'], {
          env: { 'ANSIBLE_VAULT_PASS' => 'some pass' }
        })
      }.to change {
        File.read(file)
      }.to(contents)
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

end