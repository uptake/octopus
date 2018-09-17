# frozen_string_literal: true

require_relative '../clients/bitbucket'

module Octopus
  module Commands
    class ReportDefaultBranches
      attr_reader :vcs_client, :thread_count

      def initialize(vcs_client, thread_count)
        @vcs_client = vcs_client
        @thread_count = thread_count
      end

      def run
        count = 0
        repos_list.each_slice((repos_list.size.to_f / thread_count).ceil).map do |group|
          Thread.new do
            group.each do |to_process|
              project_key, repo_slug = to_process.split('/')
              repository = Octopus::VCS::Repository.new(vcs_client, project_key, repo_slug)
              next if repository.default_branch.nil?

              default_branch_id = repository.default_branch['displayId']
              unless default_branch_id == 'master'
                count += 1
                puts "#{project_key}/#{repo_slug}\t#{default_branch_id}"
              end
            end
          end
        end.map(&:join)
        puts "#{count} repositories don't use `master` as default branch"
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
