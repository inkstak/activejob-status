# frozen_string_literal: true

class BaseJob < ActiveJob::Base
  include ActiveJob::Status

  def perform
  end
end

class AsyncJob < BaseJob
  self.queue_adapter = :async
  queue_adapter.immediate = true

  def perform
    sleep(0.5)
  end
end

class FailedJob < BaseJob
  def perform
    raise NoMethodError, "Something went wrong"
  end
end

class ProgressJob < BaseJob
  def perform
    progress.total = 100
    progress.increment(40)
  end
end

class CustomPropertyJob < BaseJob
  def perform
    status[:step] = "A"
  end
end

class UpdateJob < BaseJob
  def perform
    status.update(step: "B", progress: 25, total: 50)
  end
end
