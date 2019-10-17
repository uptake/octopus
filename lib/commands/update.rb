# frozen_string_literal: true

require 'set'

module Octopus
  module Commands
    class Update
      attr_reader :files, :directory, :vcs_client, :pr_options, :thread_count

      def initialize(files, directory, vcs_client, pr_options, thread_count)
        @files = files
        @directory = directory
        @vcs_client = vcs_client
        @pr_options = pr_options
        @thread_count = thread_count
      end

      # TODO: refactor
      def run
        created_prs = Set.new
        existed_prs = Set.new
        updated_prs = Set.new
        errored_prs = Set.new
        error_count = 0

        changesets.each_slice((changesets.size.to_f / thread_count).ceil).map do |slice|
          Thread.new do
            slice.each do |changeset|
              begin
                project_key, repo_slug = changeset[0]
                repository = Octopus::VCS::Repository.new(vcs_client, project_key, repo_slug)
                feature_branch = nil
                changes_committed = false

                changeset[1].each do |filename|
                  operation = update_single_file(repository, project_key, repo_slug, filename)
                  next unless operation

                  feature_branch = operation[:feature_branch]
                  # Once at least one change is detected for a group of files under one repo, don't toggle the flag
                  changes_committed ||= operation[:changes_committed]
                end

                if feature_branch
                  pr = repository.find_or_create_pr(feature_branch, pr_options[:title], pr_options[:description])
                  case pr[:status]
                  when :created then created_prs << pr[:text]
                  when :existed
                    changes_committed ? (updated_prs << pr[:text]) : (existed_prs << pr[:text])
                  else errored_prs << pr[:text]
                  end
                end
              rescue RestClient::Exception => e
                puts '[ERROR] An error occurred while communicating with an external service:' \
                  " #{project_key}/#{repo_slug}.\n"
                error_count += 1
                puts e.message
                puts e.response.body
              end
            end
          end
        end.map(&:join)

        updated_prs -= created_prs
        existed_prs -= updated_prs

        print_stats(created_prs, updated_prs, existed_prs, errored_prs)
      end

      private

      def changesets
        hash = {}
        Dir["#{directory}/**/{#{files.join(',')}}"].each do |path|
          matches = path.match(%r{#{directory}\/(?<project_key>.*?)\/(?<repo_slug>.*?)\/(?<filename>.*)})
          key = [matches[:project_key], matches[:repo_slug]]
          if hash.key?(key)
            hash[key] << matches[:filename]
          else
            hash[key] = [matches[:filename]]
          end
        end
        hash
      end

      def update_single_file(repository, project_key, repo_slug, filename)
        local_content = File.read("#{directory}/#{project_key}/#{repo_slug}/#{filename}")
        return unless local_content != repository.file_content(filename)

        feature_branch = begin
                           repository.find_or_create_feature_branch(pr_options[:branch])
                         rescue StandardError
                           puts 'Failed to create a feature branch: ' \
                             "#{project_key}/#{repo_slug}, #{pr_options[:branch]}"
                           return
                         end

        changes_committed = false
        unless local_content == repository.file_content(filename, feature_branch)
          repository.commit_changes(filename, local_content, feature_branch, pr_options[:message])
          changes_committed = true
        end

        { feature_branch: feature_branch, changes_committed: changes_committed }
      end

      def print_stats(created_prs, updated_prs, existed_prs, errored_prs)
        puts <<~TEXT
           \nPull requests opened: #{created_prs.count}
          \t#{created_prs.to_a.join("\n\t")}
           \nPull requests updated: #{updated_prs.count}
          \t#{updated_prs.to_a.join("\n\t")}
           \nPull requests already existed and not modified: #{existed_prs.count}
          \t#{existed_prs.to_a.join("\n\t")}
           \nPull requests could not be created due to errors: #{errored_prs.count}
          \t#{errored_prs.to_a.join("\n\t")}
        TEXT
      end
    end
  end
end
