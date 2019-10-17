# frozen_string_literal: true

module Octopus
  module VCS
    class Repository
      attr_reader :vcs_client, :project_key, :repo_slug

      def initialize(vcs_client, project_key, repo_slug)
        @vcs_client = vcs_client
        @project_key = project_key
        @repo_slug = repo_slug
      end

      def latest_commit
        vcs_client.latest_commits(project_key, repo_slug)[0]
      end

      def branch(name)
        vcs_client.branches(project_key, repo_slug, name).first
      end

      def default_branch
        @default_branch ||= vcs_client.default_branch(project_key, repo_slug)
      end

      def file_content(filename, branch = default_branch)
        raise RestClient::NotFound if branch.nil?

        vcs_client.raw(project_key, repo_slug, filename, branch['latestCommit'])
      end

      def find_or_create_feature_branch(branch_name)
        vcs_client.find_or_create_branch(branch_name, project_key, repo_slug, latest_commit['id'])
      end

      def commit_changes(filename, content, branch, message)
        vcs_client.commit_changes(project_key, repo_slug, filename, branch['id'], branch['latestCommit'],
                                  message, content)
      end

      def find_or_create_pr(branch, title, description)
        pr = vcs_client.pull_requests(project_key, repo_slug, at: branch['id'], direction: 'OUTGOING').first
        return { text: pr['links']['self'][0]['href'], status: :existed } if pr

        pr = vcs_client.create_pr \
          project_key,
          repo_slug,
          from_ref: branch['id'],
          to_ref: default_branch['id'],
          title: title,
          description: description

        { text: pr['links']['self'][0]['href'], status: :created }
      rescue StandardError
        { status: :error, text: "#{project_key}/#{project_slug} -> #{branch}" }
      end
    end
  end
end
