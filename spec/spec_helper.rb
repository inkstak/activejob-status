# frozen_string_literal: true

require 'rspec'
require 'active_job'
require 'activejob-status'

ActiveJob::Status.store = :file_store, "tmp"
Dir["#{File.dirname(__FILE__)}/jobs/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec do |mock|
    mock.syntax = :expect
  end
  config.expect_with :rspec do |expect|
    expect.syntax = :expect
  end

  config.warnings = true
end

ActiveJob::Base.queue_adapter = :inline
