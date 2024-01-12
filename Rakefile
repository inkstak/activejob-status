# frozen_string_literal: true

require "bundler/gem_tasks"
require "appraisal"
require "rspec/core/rake_task"
require "rubocop/rake_task"
require "standard/rake"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

desc "Run the full CI"
task :default do
  if ENV["APPRAISAL_INITIALIZED"]
    Rake::Task["spec"].invoke
  else
    # FYI: Standard & appraisal requires each a spawn process.

    # Additional tasks won't run after appraisal because of
    # something to do with the exit code.
    # https://github.com/thoughtbot/appraisal/issues/144

    # Standard may be tainted by the rubocop task and
    # report offenses from other plugins putted in .rubocop_todo.yml
    # https://github.com/testdouble/standard/issues/480

    fail unless system "bundle exec appraisal rspec"
    fail unless system "bundle exec rubocop"
    fail unless system "bundle exec rake standard"
  end
end
