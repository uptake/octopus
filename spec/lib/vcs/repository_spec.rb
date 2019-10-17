# frozen_string_literal: true

require 'vcs/repository'
require 'rest-client'
RSpec.describe Octopus::VCS::Repository do
  let(:vcs_client) { double('vcs_client') }
  subject { described_class.new(vcs_client, 'project_key', 'repo_slug') }

  describe '#latest_commit' do
    it 'returns the first element from `latest_commits` collection provided by vcs_client' do
      expect(vcs_client).to receive(:latest_commits).and_return([{ 'sha' => 'wombat' }, { 'sha' => 'kangoo' }])
      expect(subject.latest_commit).to eq('sha' => 'wombat')
    end
  end

  describe '#default_branch' do
    it 'returns the default branch for a given repo and caches result in an ivar' do
      allow(vcs_client).to receive(:default_branch).and_return('wombat_branch')

      expect(vcs_client).to receive(:default_branch).once
      3.times { expect(subject.default_branch).to eq 'wombat_branch' }
    end
  end

  describe '#file_content' do
    it 'returns raw file content from a default branch if other is not specified' do
      expect(subject).to receive(:default_branch).and_return('wombat_branch')
      expect(vcs_client).to receive(:raw).and_return("my\ncontent")

      expect(subject.file_content('Wombatfile')).to eq "my\ncontent"
    end

    it 'returns raw file content from a specified branch' do
      expect(subject).to_not receive(:default_branch)
      expect(vcs_client).to receive(:raw).and_return("my\ncontent")

      expect(subject.file_content('Wombatfile', 'branch')).to eq "my\ncontent"
    end
  end

  describe '#find_or_create_feature_branch' do
    it 'proxies the task to the underlying vcs client' do
      expect(subject).to receive(:latest_commit).and_return('id' => 'wombat')
      expect(vcs_client).to receive(:find_or_create_branch)

      subject.find_or_create_feature_branch('branch')
    end
  end
end
