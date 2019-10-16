# frozen_string_literal: true

require 'clients/gitlab'
require 'support/gitlab_stubs'

# rubocop:disable Metrics/BlockLength
RSpec.describe Octopus::Clients::Gitlab do
  subject { described_class.new('url', 'wombat', 'koala') }

  describe '#projects' do
    it 'returns a list of gitlab groups' do
      stub = stub_projects_200
      projects = subject.projects

      expect(stub).to have_been_requested
      expect(projects).to be_a Array
      expect(projects.first.keys).to include 'name'
    end
  end
end
# rubocop:enable Metrics/BlockLength
