# frozen_string_literal: true

require 'rest-client'
require 'json'

module Octopus
  module Clients
    class Gitlab
      API_PATH = 'api/v4'
      attr_reader :base_url, :username, :password

      def initialize(base_url, username, password)
        @base_url = base_url
        @username = username
        @password = password
      end

      # What Bitbucket calls Projects/Repos, Gitlab and Github call Groups/Projects.
      # For now, maintain compatibility with Bitbucket.
      def projects(limit = 1000)
        url = "#{base_url}/#{API_PATH}/groups"
        response = RestClient::Request.execute(method: :get, url: url, headers: { private_token: password })
        JSON.parse(response.body).first(limit).each do |group|
          # For now, maintain compatibility with Bitbucket.
          group['key'] = group.delete('path')
        end
      end

      def repos(project_key, limit = 1000)
      end

      def raw(project_kew, repo_slug, path, at = nil)
      end

      def branches(project_key, repo_slug, display_id = nil)
      end

      def default_branch(project_key, repo_slug)
      end

      def create_branch(name, project_key, repo_slug, start_point)
      end

      def find_or_create_branch(name, project_key, repo_slug, start_point)
      end

      def latest_commits(project_key, repo_slug, limit = 100)
      end

      # rubocop:disable Metrics/ParameterLists
      def commit_changes(project_key, repo_slug, path, branch, source_commit_id, commit_message, content)
      end
      # rubocop:enable Metrics/ParameterLists

      def pull_requests(project_key, repo_slug, at: nil, direction: 'INCOMING', limit: 1000)
      end

      # rubocop:disable Metrics/ParameterLists
      def create_pr(project_key, repo_slug, from_ref:, to_ref:, title:, description:)
      end
      # rubocop:enable Metrics/ParameterLists
    end
  end
end
