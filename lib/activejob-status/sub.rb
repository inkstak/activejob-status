module ActiveJob::Status
  class Sub
    delegate :[], :to_s, :inspect, to: :read
    delegate :queued?, :working?, :completed?, to: :status_inquiry

    def initialize(job)
      @job = job
    end

    def job_id
      Storage.job_id(@job)
    end

    def read
      Storage.read(@job)
    end

    def status
      read[:status]
    end

    def progress
      read[:progress].to_f / read[:total].to_f
    end

  protected

    def status_inquiry
      status.to_s.inquiry
    end
  end
end
