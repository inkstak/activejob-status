module ActiveJob
  module Status
    class Progress
      attr_reader :job, :total, :progress

      delegate :[], :to_s, :to_json, :inspect, to: :to_h
      delegate :status, to: :job, prefix: true

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

      def to_h
        { progress: @progress, total: @total }
      end

      private

      def update
        @progress = yield if block_given?
        job_status.update(to_h)
        self
      end
    end
  end
end
