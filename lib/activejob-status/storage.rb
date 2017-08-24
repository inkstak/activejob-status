module ActiveJob::Status
  module Storage
    class << self
      def store
        ActiveJob::Status.store
      end

      def options
        ActiveJob::Status.options
      end

      def job_id(job)
        job.is_a?(String) ? job : job.job_id
      end

      def key(job)
        "activejob:status:#{job_id(job)}"
      end

      def read(job)
        store.read(key(job)) || {}
      end

      def write(job, message)
        store.write(key(job), message, expires_in: options[:expires_in])
      end

      def update(job, message)
        write(job, read(job).merge(message))
      end

      def delete(job)
        store.delete(key(job))
      end
    end
  end
end
