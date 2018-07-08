RSpec.describe 'medusa help', type: :bash do
  subject { medusa_script }

  it 'works' do
    run_script(subject, ['help'])

    expect(subject.exit_code).to eq(0)
    expect(subject.stdout).to include('medusa')
  end
end