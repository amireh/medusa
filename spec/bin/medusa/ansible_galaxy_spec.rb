RSpec.describe 'medusa ansible-galaxy', type: :bash, docker: true, ansible: true do
  subject { medusa_script }

  it 'works' do
    expect(run_script(subject, ['ansible-galaxy', '--help'])).to be true
    expect(subject.stdout).to include('Usage: ansible-galaxy ')
  end
end