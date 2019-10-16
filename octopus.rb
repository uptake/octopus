# frozen_string_literal: true

require 'byebug'
require_relative 'lib/clients/bitbucket'
require_relative 'lib/clients/gitlab'
require_relative 'lib/commands/fetch'
require_relative 'lib/commands/update'
require_relative 'lib/options'
require_relative 'lib/vcs/repository'
$VERBOSE = nil

unless RUBY_VERSION.to_f >= 2.5
  puts 'Octopus requires Ruby 2.5.0 and above'
  exit 1
end

options_parser = Octopus::Options.new
unless options_parser.valid?
  puts options_parser.errors.values.join("\n")
  exit 1
end

options = options_parser.options

vcs_client = case options[:scm_provider].downcase
             when 'bitbucket'
               Octopus::Clients::Bitbucket.new(options[:base_url], options[:username], options[:password])
             when 'gitlab'
               Octopus::Clients::Gitlab.new(options[:base_url], options[:username], options[:password])
             else
               puts "Unknown SCM provider #{options[:scm_provider]}. Available values are: " \
                 "#{Octopus::Options::SCM_PROVIDERS.join(', ')}."
               exit 1
             end

command = case options[:command]
          when Octopus::Options::COMMAND_FETCH
            Octopus::Commands::Fetch.new(options[:files], options[:directory], vcs_client, options[:thread_count],
                                         options[:branch])
          when Octopus::Options::COMMAND_UPDATE
            Octopus::Commands::Update.new(options[:files], options[:directory], vcs_client, options_parser.pr_options,
                                          options[:thread_count])
          end

begin
  command.run
rescue StandardError => e
  puts e.message
  exit 1
end
