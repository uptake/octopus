# frozen_string_literal: true

require_relative '../clients/bitbucket'

require 'date'

module Octopus
  module Commands
    class FindStale
      attr_reader :last_committed_date, :vcs_client, :thread_count

      def initialize(last_committed_date, vcs_client, thread_count)
        @last_committed_date = DateTime.parse(last_committed_date).to_date
        @vcs_client = vcs_client
        @thread_count = thread_count
      end

      def run
        active_repos_count = 0
        stale_repos_count = 0
        empty_repos_count = 0
        stale_repos = {}
        active_repos = {}
        empty_repos = {}

        repos_list.each_slice((repos_list.size.to_f / thread_count).ceil).map do |group|
          Thread.new do
            group.each do |to_process|
              project_key, repo_slug = to_process.split('/')
              repository = Octopus::VCS::Repository.new(vcs_client, project_key, repo_slug)

              tip_commit_date = DateTime.strptime((repository.latest_commit['committerTimestamp'].to_i / 1000).to_s, "%s").to_date rescue nil

              if tip_commit_date.nil?
                empty_repos[project_key] = [] unless empty_repos.key?(project_key)
                empty_repos[project_key] << repo_slug
                empty_repos_count += 1
              elsif tip_commit_date >= last_committed_date
                active_repos[project_key] = [] unless active_repos.key?(project_key)
                active_repos[project_key] << repo_slug
                active_repos_count += 1
              else
                stale_repos[project_key] = [] unless stale_repos.key?(project_key)
                stale_repos[project_key] << repo_slug
                stale_repos_count += 1
              end
            end
          end
        end.map(&:join)

        puts "Analysis complete: #{active_repos_count} have commits after #{last_committed_date}, and #{stale_repos_count} repos are stale, #{empty_repos_count} repos have 0 commits."

        puts "\nActive repos:"
        active_repos.each do |project_key, repos|
          puts "#{project_key}: #{repos.join(', ')}"
        end

        puts "\nStale repos:"
        stale_repos.each do |project_key, repos|
          puts "#{project_key}: #{repos.join(', ')}"
        end

        puts "\nEmpty repos:"
        empty_repos.each do |project_key, repos|
          puts "#{project_key}: #{repos.join(', ')}"
        end
      end

      private

      def repos_list
        return @repos_list if @repos_list

        @repos_list = []

        vcs_client.projects.map do |project|
          @repos_list << vcs_client.repos(project['key']).map { |repo| "#{project['key']}/#{repo['slug']}" }
        end
        @repos_list.flatten!
      end
    end
  end
end
