RSpec.describe 'medusa ansible', type: :bash, docker: true, ansible: true do
  subject { medusa_script }

  it 'works' do
    expect(run_script(subject, ['ansible', '--help'])).to be true
    expect(subject.stdout).to include('Usage: ansible ')
  end

  it "utilizes ANSIBLE_VAULT_PASS" do
    env = {
      "ANSIBLE_VAULT_PASS" => "some secret", # must match what used to encrypt_string the content
      "ANSIBLE_STDOUT_CALLBACK" => "minimal"
    }

    expect(
      run_script(subject, ['ansible', 'localhost', '-m', 'debug', '-a', 'var=secret_var', '-e', '@vars/secrets.yml'], env: env)
    ).to be true

    expect(subject.stdout).to include('"secret_var": "foo"')
  end
end