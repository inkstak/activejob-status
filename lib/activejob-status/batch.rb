# frozen_string_literal: true

module ActiveJob
  module Status
    class Batch
      def initialize(jobs)
        @jobs = jobs
        @storage = ActiveJob::Status::Storage.new
      end

      def status
        statuses = read.values.pluck(:status)

        if statuses.include?(:failed)
          :failed
        elsif statuses.all?(:queued)
          :queued
        elsif statuses.all?(:completed)
          :completed
        else
          :working
        end
      end

      def read
        @storage.read_multi(@jobs)
      end
      alias_method :to_h, :read
    end
  end
end
