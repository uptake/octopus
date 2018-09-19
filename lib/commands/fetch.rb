# frozen_string_literal: true

require_relative '../clients/bitbucket'

module Octopus
  module Commands
    class Fetch
      attr_reader :directory, :files, :vcs_client, :branch_name, :thread_count

      def initialize(files, directory, vcs_client, thread_count, branch_name = nil)
        @files = files
        @directory = directory
        @vcs_client = vcs_client
        @branch_name = branch_name
        @thread_count = thread_count
      end

      def run
        downloaded_count = 0
        skipped_count = 0

        repos_list.each_slice((repos_list.size.to_f / thread_count).ceil).map do |group|
          Thread.new do
            group.each do |to_process|
              project_key, repo_slug = to_process.split('/')
              repository = Octopus::VCS::Repository.new(vcs_client, project_key, repo_slug)

              files.each do |filename|
                file_content = begin
                                 branch = branch_name.nil? ? repository.default_branch : repository.branch(branch_name)
                                 repository.file_content(filename, branch)
                               rescue RestClient::NotFound
                                 skipped_count += 1
                                 next
                               end
                path = "#{directory}/#{project_key}/#{repo_slug}"
                puts "Downloading #{path}/#{filename}"

                FileUtils.mkdir_p(File.dirname("#{path}/#{filename}"))
                File.write("#{path}/#{filename}", file_content)
                downloaded_count += 1
              end
            end
          end
        end.map(&:join)

        puts "Download complete. #{downloaded_count} files downloaded, " \
          "#{skipped_count} repositories skipped because there was no such files: #{files.join(', ')}."
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
