# frozen_string_literal: true

require "bundler/setup"
Bundler.setup

require "simplecov"
SimpleCov.start

require "active_job"
require "activejob-status"
require "timecop"

Dir.mkdir("tmp") unless Dir.exist?("tmp")

ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(File.open("tmp/log", "w")))
ActiveJob::Status.store = :memory_store

RSpec.configure do |config|
  config.order = "random"
  config.expect_with :rspec do |expect|
    expect.syntax = :expect
  end

  config.include ActiveJob::TestHelper

  config.after do
    Timecop.return
  end
end
