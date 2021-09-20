# frozen_string_literal: true

module ActiveJob
  module Status
    class Status
      delegate :[], :to_s, :to_json, :inspect, to: :read
      delegate :queued?, :working?, :completed?, :failed?, to: :status_inquiry

      def initialize(job, options = {})
        options  = ActiveJob::Status.options.merge(options)
        @storage = ActiveJob::Status::Storage.new(options)
        @job     = job
      end

      def []=(key, value)
        update({ key => value }, force: true)
      end

      def read
        @storage.read(@job)
      end
      alias to_h read

      def update(message, options = {})
        @storage.update(@job, message, **options)
      end

      def delete
        @storage.delete(@job)
      end

      def job_id
        @storage.job_id(@job)
      end

      def status
        read[:status]
      end

      def progress
        read[:progress].to_f / read[:total].to_f
      end

      def present?
        read.present?
      end

      def status_inquiry
        status.to_s.inquiry
      end
    end
  end
end
