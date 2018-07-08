RSpec.describe 'medusa info', type: :bash do
  subject { medusa_script }

  it 'works' do
    root = Support::ROOT_DIR

    expect(run_script(subject, ['info'])).to be true

    expect(subject.stdout).to include("MEDUSA_DIR=#{root}")
    expect(subject.stdout).to include("MEDUSA_BIN=#{File.join(root, 'bin/medusa')}")
  end
end