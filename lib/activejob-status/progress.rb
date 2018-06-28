module ActiveJob
  module Status
    class Progress
      delegate :[], :to_s, :to_json, :inspect, to: :hash

      def initialize(job)
        @job      = job
        @total    = 100
        @progress = 0
      end

      def total=(num)
        @total = num
        update
      end

      def progress=(num)
        update { num }
      end

      def increment(num = 1)
        update { @progress + num }
      end

      def decrement(num = 1)
        update { @progress - num }
      end

      def finish
        update { @total }
      end

      private

      def update
        @progress = yield if block_given?
        @job.status.update(hash)
        self
      end

      def hash
        { progress: @progress, total: @total }
      end
    end
  end
end
