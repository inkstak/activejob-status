module ActiveJob::Status
  module Storage
    class << self
      def store
        ActiveJob::Status.store
      end

      def key(job)
        id = job.is_a?(String) ? job : job.job_id
        "activejob:status:#{id}"
      end

      def read(job)
        store.read(key(job)) || {}
      end

      def write(job, message)
        store.write(key(job), message, expires_in: DEFAULT_EXPIRY)
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
