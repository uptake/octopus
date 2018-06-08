# frozen_string_literal: true

begin
  desc 'Runs rubocop'
  task :rubocop do
    sh 'rubocop'
  end

  task :default do
    Rake::Task[:rubocop].invoke
  end
rescue LoadError => e
  puts "Error loading files in Rakefile. #{e.message}"
end
