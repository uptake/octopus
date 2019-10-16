# frozen_string_literal: true

require 'optparse'

module Octopus
  class Options
    COMMAND_FETCH = 'fetch'
    COMMAND_UPDATE = 'update'
    DEFAULT_SCM_PROVIDER = 'bitbucket'
    DEFAULT_THREAD_COUNT = 500
    FETCH_OPTIONS = %i[command directory files url username password provider].freeze
    SCM_PROVIDERS = %w[bitbucket gitlab].freeze

    attr_reader :options, :errors

    def initialize(default_argv = ARGV)
      @options = {
        username: nil, password: nil, command: nil, directory: nil, base_url: nil, files: '', message: nil,
        title: nil, branch: nil, description: nil, scm_provider: DEFAULT_SCM_PROVIDER,
        thread_count: DEFAULT_THREAD_COUNT
      }
      @errors = []
      cli_options(default_argv).parse!
      validate
    end

    def valid?
      errors.empty?
    end

    def validate
      case options[:command]
      when nil then @errors << 'Options is not set: --command.'
      when COMMAND_FETCH
        @errors = Hash[options.slice(*FETCH_OPTIONS).select { |_, v| v.nil? }
                              .map { |k, _| [k, "Option is not set: --#{k}."] }]
      when COMMAND_UPDATE
        @errors = Hash[options.select { |_, v| v.nil? }.map { |k, _| [k, "Option is not set: --#{k}."] }]
      else
        @errors << { command: "Unknown command. Must be one of the following: #{COMMAND_FETCH}, #{COMMAND_UPDATE}." }
      end
    end

    def pr_options
      options.slice(:branch, :message, :title, :description)
    end

    private

    def cli_options(default_argv)
      parser = OptionParser.new
      parser.default_argv = default_argv

      parser.banner = 'Usage: ./octopus.rb [options]'

      parser.on('-u', '--username=USERNAME', 'SCM provider username.') do |u|
        options[:username] = u
      end

      parser.on('-p', '--password=PASSWORD', 'SCM provider password.') do |p|
        options[:password] = p
      end

      parser.on('-c', '--command=COMMAND', 'Octopus command: [fetch, update].') do |c|
        options[:command] = c
      end

      parser.on('-d', '--directory=DIRECTORY', 'Directory to fetch files into / to read files for update.') do |d|
        options[:directory] = d.gsub('//', '/').chomp('/')
      end

      parser.on('--url=URL', 'SCM host URL.') do |url|
        options[:base_url] = url
      end

      parser.on('--scm-provider=PROVIDER',
                "SCM provider. Available options: #{SCM_PROVIDERS.join(', ')}. Default: #{DEFAULT_SCM_PROVIDER}") do |p|
        options[:scm_provider] = p
      end

      parser.on('--thread-count=COUNT', "Thread count. Default: #{DEFAULT_THREAD_COUNT}.") do |c|
        options[:thread_count] = c.to_i
      end

      parser.on('-f', '--files=FILENAME', 'A comma-separated list of files to fetch/update.') do |f|
        options[:files] = f.split(',').map(&:strip)
      end

      parser.on('-m', '--message=MESSAGE', 'Commit message.') do |m|
        options[:message] = m
      end

      parser.on('-t', '--title=TITLE', 'Pull request title.') do |t|
        options[:title] = t
      end

      parser.on('-b', '--branch=BRANCH', 'Branch name. Optional for "fetch" command. In the context of "update"' \
                ' - a branch that will contain changes.') do |b|
        options[:branch] = b
      end

      parser.on('--description=DESCRIPTION', 'Pull request descriptions.') do |d|
        options[:description] = d
      end
    end
  end
end
