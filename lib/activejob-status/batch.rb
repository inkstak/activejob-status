# frozen_string_literal: true

module ActiveJob
  module Status
    class Batch
      def initialize(*jobs)
        @statuses = jobs.map { |job| ActiveJob::Status.get(job) }
      end

      def status
        if @statuses.all? { |status| status[:status] == :queued }
          :queued
        elsif @statuses.any? { |status| status[:status] == :failed }
          :failed
        elsif @statuses.all? { |status| status[:status] == :completed }
          :completed
        else
          :working
        end
      end
    end
  end
end
