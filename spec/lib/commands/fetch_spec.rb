# frozen_string_literal: true

require 'commands/fetch'
require 'vcs/repository'
RSpec.describe Octopus::Commands::Fetch do
  let(:vcs_client) { double(projects: [{ 'key' => 'WMBT' }, { 'key' => 'KNG' }]) }

  describe '#repos_list' do
    before do
      allow(vcs_client).to receive(:repos).with('WMBT')
                                          .and_return([{ 'slug' => 'wombat_repo' }, { 'slug' => 'quokka_repo' }])

      allow(vcs_client).to receive(:repos).with('KNG').and_return([{ 'slug' => 'kangoo_repo' }])
    end

    it 'returns a flat list of all project/repo pairs that will need processing' do
      subject = described_class.new([], '.', vcs_client, 1)
      expect(subject.send(:repos_list)).to eq(%w[WMBT/wombat_repo WMBT/quokka_repo KNG/kangoo_repo])
    end
  end

  describe '#run' do
    subject do
      described_class.new(['path/deeper/than/root/Jenkinsfile'], 'spec/.mockfiles/jenkinsfiles', vcs_client, 1)
    end

    before do
      allow(subject).to receive(:repos_list).and_return(%w[WMBT/wombat KNG/kangoo])
      allow(vcs_client).to receive(:default_branch).and_return('master')
      allow(vcs_client).to receive(:raw).and_return('some text')
    end

    it 'creates a nested path to fetch files located deeper than the root of repositories' do
      expect(FileUtils).to receive(:mkdir_p).with('spec/.mockfiles/jenkinsfiles/WMBT/wombat/path/deeper/than/root')
      expect(FileUtils).to receive(:mkdir_p).with('spec/.mockfiles/jenkinsfiles/KNG/kangoo/path/deeper/than/root')
      allow(File).to receive(:write)
      subject.run
    end
  end
end
