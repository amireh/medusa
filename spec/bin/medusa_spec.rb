RSpec.describe 'medusa', type: :bash, docker: true do
  subject { medusa_script }

  it 'resolves itself as a symlink' do
    symlink = tmp_path('medusa')
    normal = File.join(Support::ROOT_DIR, 'bin/medusa')

    expect(
      system("ln -s #{normal} #{symlink}")
    ).to be true

    stdout = `#{symlink} info`

    expect(stdout).to include("MEDUSA_BIN=#{File.join(Support::ROOT_DIR, 'bin', 'medusa')}")
    expect(stdout).to include("MEDUSA_DIR=#{File.join(Support::ROOT_DIR)}")

    expect(`#{normal} info`).to eq(`#{symlink} info`)
  end
end