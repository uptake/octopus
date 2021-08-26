# frozen_string_literal: true

require 'rest-client'
require 'json'

module Octopus
  module Clients
    class GitHub
      attr_reader :base_url, :auth_token

      def initialize(base_url, auth_token)
        @base_url = base_url
        @auth_token = auth_token
      end

      # Can't get a list of organizations in an enterprise
      # https://www.reddit.com/r/github/comments/o5whds/list_all_organizations_in_enterprise_githubcom/
      def projects(limit = 100)
        raise 'Obtaining projcts(organizations) for an enterprise in GitHub is not implemented, please use the --projects CLI flag.'
      end

      def repos(project_key, limit = 100)
        url = "#{base_url}/orgs/#{project_key}/repos?per_page=#{limit}"
        response = RestClient::Request.execute(method: :get, url: url, headers: { :Authorization => "token #{auth_token}" })
        result = JSON.parse(response.body)
        result.each { |v| v['slug'] = v['name'] }
      end

      def raw(project_key, repo_slug, path, at = nil)
        url = "#{base_url}/repos/#{project_key}/#{repo_slug}/contents/#{path}"
        response = RestClient::Request.execute(method: :get, url: url, headers: { :Authorization => "token #{auth_token}", :Accept => 'applicatioin/vnd.github.v3.raw' })
        response.body
      end

      def default_branch(org = nil, repo = nil)
        url = "#{base_url}/repos/#{org}/#{repo}"
        response = RestClient::Request.execute(method: :get, url: url, headers: { :Authorization => "token #{auth_token}" })
        branch_name = JSON.parse(response.body)['default_branch']

        # `latestCommit` is here to match the current interface that was originally used for Bitbucket fetch; in case of GitHub, this value is effectively ignored.
        { 'id' => branch_name, 'latestCommit' => 'sha' }
      end

      def branches(org, repo, name)
        url = "#{base_url}/repos/#{project_key}/#{repo}/branches/#{name}"
        response = RestClient::Request.execute(method: :get, url: url, headers: { :Authorization => "token #{auth_token}" })
        JSON.parse(response.body)
      end
    end
  end
end
