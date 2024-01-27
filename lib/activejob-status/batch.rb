# frozen_string_literal: true

module ActiveJob
  module Status
    class Batch
      def initialize(jobs)
        @jobs = jobs
        @storage = ActiveJob::Status::Storage.new
      end

      def status
        if @jobs.all? { |job| status_for(job) == :queued }
          :queued
        elsif @jobs.any? { |job| status_for(job) == :failed }
          :failed
        elsif @jobs.all? { |job| status_for(job) == :completed }
          :completed
        else
          :working
        end
      end

      private

      def statuses
        @statuses ||= @storage.read_multi(@jobs)
      end

      def status_for(job)
        statuses.dig(@storage.key(job), :status)
      end
    end
  end
end
