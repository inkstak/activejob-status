# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"
require "standard/rake"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task :default do
  Rake::Task["spec"].invoke
  Rake::Task["rubocop"].invoke

  # FYI: Standard requires a spawn process.
  # Otherwise it may be tainted by the rubocop task and
  # report offenses from other plugins putted in .rubocop_todo.yml
  # https://github.com/testdouble/standard/issues/480
  fail unless system "bundle exec rake standard"
end
