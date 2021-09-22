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

class ThrottledJob < BaseJob
  def status
    @status ||= ActiveJob::Status::Status.new(self, throttle_interval: 0.5)
  end
end

class ThrottledSettersJob < ThrottledJob
  def perform
    status[:step] = "A"
    progress.progress = 0
    progress.total = 10

    status[:step] = "B"
    progress.progress = 1
    progress.total = 20

    status[:step] = "C"
    progress.progress = 2
    progress.total = 30
  end
end

class ThrottledUpdatesJob < ThrottledJob
  def perform
    status.update(step: "A", progress: 0, total: 10)
    status.update(step: "B", progress: 1, total: 20)
    status.update(step: "C", progress: 2, total: 30)
  end
end

class ThrottledForcedUpdatesJob < ThrottledJob
  def perform
    status.update({step: "A", progress: 0, total: 10}, force: true)
    status.update({step: "B", progress: 1, total: 20}, force: true)
    status.update({step: "C", progress: 2, total: 30}, force: true)
  end
end
