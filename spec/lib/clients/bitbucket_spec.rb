# frozen_string_literal: true

require 'clients/bitbucket'
require 'support/bitbucket_stubs'

# rubocop:disable Metrics/BlockLength
RSpec.describe Octopus::Clients::Bitbucket do
  subject { described_class.new('url', 'wombat', 'koala') }

  describe '#projects' do
    it 'returns a list of bitbucket projects' do
      stub = stub_projects_200
      projects = subject.projects

      expect(stub).to have_been_requested
      expect(projects).to be_a Array
      expect(projects.first.keys).to include 'name'
    end
  end

  describe '#repos' do
    it 'returns a list of bitbucket repositories for a given project' do
      stub = stub_project_repos_200('my_project')
      repos = subject.repos('my_project')

      expect(stub).to have_been_requested
      expect(repos).to be_a Array
      expect(repos.first.keys).to include 'name'
    end
  end

  describe '#raw' do
    it 'returns ' do
      stub = stub_get_raw_200('my_project', 'my_repo', 'Jenkinsfile')
      subject.raw('my_project', 'my_repo', 'Jenkinsfile')

      expect(stub).to have_been_requested
    end
  end

  describe '#branches' do
    it 'returns a list of branches for a repository' do
      stub = stub_repo_branches_200('my_project', 'my_repo')
      branches = subject.branches('my_project', 'my_repo')

      expect(stub).to have_been_requested
      expect(branches).to be_a Array
      expect(branches.first).to include 'id', 'isDefault'
    end
  end

  describe '#default_branch' do
    it 'returns a default branch for a repository' do
      stub = stub_repo_default_branch_200('my_project', 'my_repo')
      default_branch = subject.default_branch('my_project', 'my_repo')

      expect(stub).to have_been_requested
      expect(default_branch).to be_a Hash
      expect(default_branch).to include 'id', 'isDefault'
    end
  end

  describe '#create_branch' do
    it 'makes a call to create a branch and returns its json structure' do
      stub = stub_repo_create_branch_200('branch_name', 'my_project', 'my_repo', 'e12dsfd343')
      branch = subject.create_branch('branch_name', 'my_project', 'my_repo', 'e12dsfd343')

      expect(stub).to have_been_requested
      expect(branch).to be_a Hash
      expect(branch.keys).to include 'id', 'isDefault'
    end
  end

  describe '#find_or_create_branch' do
    it 'creates a branch if it doesn not exist' do
      expect(subject).to receive(:branches).and_return([])
      expect(subject).to receive(:create_branch).and_return('displayId' => 'branch')

      expect(subject.find_or_create_branch('branch', 'project', 'repo_slug', 'latest-commit-sha')['displayId']).to \
        eq 'branch'
    end

    it 'finds a branch if it already exists' do
      expect(subject).to receive(:branches).and_return(
        [{ 'displayId' => 'wombat' }, { 'displayId' => 'branch' }]
      )

      expect(subject.find_or_create_branch('branch', 'project', 'repo_slug', 'latest-commit-sha')['displayId']).to \
        eq 'branch'
    end
  end

  describe '#latest_commits' do
    it 'returns a list of lates commits w/o pagination' do
      stub = stub_repo_commits_200('my_project', 'my_repo')
      commits = subject.latest_commits('my_project', 'my_repo')

      expect(stub).to have_been_requested
      expect(commits).to be_a Array
      expect(commits.first.keys).to include 'committerTimestamp', 'message', 'committer', 'id', 'displayId'
    end
  end

  describe '#commit_changes' do
    it 'makes a call to create a commit and returns its details' do
      stub = stub_repo_create_commit_200('my_project', 'my_repo', 'Wombatfile')
      commit = subject.commit_changes('my_project', 'my_repo', 'Wombatfile', 'branch_name', 'e12dsfd343',
                                      'My commit message', "My new\nWombatfile\ncontent")

      expect(stub).to have_been_requested
      expect(commit).to be_a Hash
      expect(commit.keys).to include 'committer', 'author', 'message', 'displayId'
    end
  end

  describe '#pull_requests' do
    it 'returns a list of pull requests objects w/o pagination' do
      stub = stub_repo_pull_requests_200('my_project', 'my_repo')
      pull_requests = subject.pull_requests('my_project', 'my_repo')

      expect(stub).to have_been_requested
      expect(pull_requests).to be_a Array
      expect(pull_requests.first.keys).to include 'title', 'description', 'open', 'closed', 'fromRef', 'toRef'
    end
  end

  describe '#create_pr' do
    it 'makes a call to create a pull request and returns its details' do
      stub = stub_repo_create_pull_request_200('my_project', 'my_repo')
      pull_request = subject.create_pr('my_project', 'my_repo', from_ref: 'feature_branch', to_ref: 'master',
                                                                title: 'Test PR', description: 'My description')

      expect(stub).to have_been_requested
      expect(pull_request).to be_a Hash
      expect(pull_request).to include 'title', 'description', 'open', 'closed', 'fromRef', 'toRef'
    end
  end
end
# rubocop:enable Metrics/BlockLength
