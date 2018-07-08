RSpec.describe 'medusa/completions/bash', type: :bash do
  let(:root) { Support::ROOT_DIR }
  let(:path) { File.join(root, 'completions/medusa.bash') }

  it 'can be sourced' do
    subject = a_script(File.read(path))

    run_script(subject)
    expect(subject.exit_code).to eq(0)
  end

  it 'invokes "medusa commands"' do
    subject = a_script <<-EOF
      source '#{path}'

      _medusa
    EOF

    expect(subject).to receive(:medusa).with_args('commands').and_yield { |*|
      <<-SCRIPT
        echo "foo"
        echo "bar"
      SCRIPT
    }

    run_script(subject, env: {
      "COMP_WORDS" => "foo",
      "COMP_CWORD" => "1"
    })
  end
end