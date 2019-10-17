# frozen_string_literal: true

require 'rest-client'
require 'json'

module Octopus
  module Clients
    class Bitbucket
      attr_reader :base_url, :username, :password

      def initialize(base_url, username, password)
        @base_url = base_url
        @username = username
        @password = password
      end

      def projects(limit = 1000)
        url = "#{base_url}/rest/api/1.0/projects?limit=#{limit}"
        response = RestClient::Request.execute(method: :get, url: url, user: username, password: password)
        JSON.parse(response.body)['values']
      end

      def repos(project_key, limit = 1000)
        url = "#{base_url}/rest/api/1.0/projects/#{project_key}/repos?limit=#{limit}"
        response = RestClient::Request.execute(method: :get, url: url, user: username, password: password)
        JSON.parse(response.body)['values']
      end

      def raw(project_key, repo_slug, path, at = nil)
        url = "#{base_url}/rest/api/1.0/projects/#{project_key}/repos/#{repo_slug}/raw/#{path}?at=#{at}"
        response = RestClient::Request.execute(method: :get, url: url, user: username, password: password)
        response.body
      end

      def branches(project_key, repo_slug, display_id = nil)
        url = "#{base_url}/rest/api/1.0/projects/#{project_key}/repos/#{repo_slug}/branches"
        response = RestClient::Request.execute \
          method: :get,
          headers: { 'Content-Type' => 'application/json', params: { filterText: display_id, limit: 100 } },
          url: url,
          user: username,
          password: password

        JSON.parse(response.body)['values']
      end

      def default_branch(project_key, repo_slug)
        url = "#{base_url}/rest/api/1.0/projects/#{project_key}/repos/#{repo_slug}/branches/default"
        response = RestClient::Request.execute \
          method: :get,
          headers: { 'Content-Type' => 'application/json' },
          url: url,
          user: username,
          password: password

        JSON.parse(response.body)
      end

      def create_branch(name, project_key, repo_slug, start_point)
        url = "#{base_url}/rest/branch-utils/1.0/projects/#{project_key}/repos/#{repo_slug}/branches"
        response = RestClient::Request.execute \
          method: :post,
          headers: { 'Content-Type' => 'application/json' },
          url: url,
          user: username,
          password: password,
          payload: { name: name, startPoint: start_point }.to_json

        JSON.parse(response.body)
      end

      def find_or_create_branch(name, project_key, repo_slug, start_point)
        result = branches(project_key, repo_slug, name).find { |b| b['displayId'] == name }

        return result unless result.nil?

        create_branch(name, project_key, repo_slug, start_point)
      end

      def latest_commits(project_key, repo_slug, limit = 100)
        url = "#{base_url}/rest/api/1.0/projects/#{project_key}/repos/#{repo_slug}/commits?limit=#{limit}"
        response = RestClient::Request.execute(method: :get, url: url, user: username, password: password)
        JSON.parse(response.body)['values']
      end

      # rubocop:disable Metrics/ParameterLists
      def commit_changes(project_key, repo_slug, path, branch, source_commit_id, commit_message, content)
        url = "#{base_url}/rest/api/1.0/projects/#{project_key}/repos/#{repo_slug}/browse/#{path}"

        response = RestClient::Request.execute \
          method: :put,
          headers: { 'Content-Type' => 'multipart/form-data' },
          url: url,
          user: username,
          multipart: true,
          password: password,
          verify_ssl: false,
          payload: {
            branch: branch,
            content: Tempfile.new.tap { |f| f.write(content) && f.rewind },
            sourceCommitId: source_commit_id,
            message: commit_message
          }

        JSON.parse(response.body)
      end
      # rubocop:enable Metrics/ParameterLists

      def pull_requests(project_key, repo_slug, at: nil, direction: 'INCOMING', limit: 1000)
        url = "#{base_url}/rest/api/1.0/projects/#{project_key}/repos/#{repo_slug}/pull-requests?limit=#{limit}"
        response = RestClient::Request.execute \
          method: :get,
          url: url,
          user: username,
          password: password,
          headers: { params: { at: at, direction: direction } }
        JSON.parse(response.body)['values']
      end

      # rubocop:disable Metrics/ParameterLists
      def create_pr(project_key, repo_slug, from_ref:, to_ref:, title:, description:)
        url = "#{base_url}/rest/api/1.0/projects/#{project_key}/repos/#{repo_slug}/pull-requests"

        payload = {
          title: title,
          description: description,
          fromRef: { id: from_ref },
          toRef: { id: to_ref }
        }

        JSON.parse(RestClient::Request.execute(method: :post, url: url, user: username, password: password,
                                               headers: { 'Content-Type' => 'application/json' },
                                               payload: payload.to_json))
      end
      # rubocop:enable Metrics/ParameterLists
    end
  end
end
