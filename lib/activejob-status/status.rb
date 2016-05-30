module ActiveJob::Status
  class Status
    delegate :[], :to_s, :inspect, to: :read
    delegate :queued?, :working?, :completed?, to: :status_inquiry

    def initialize(job)
      @job = job
    end

    def []= key, value
      update(key => value)
    end

    def read
      Storage.read(@job)
    end

    def update(message)
      Storage.update(@job, message)
    end

    def delete
      Storage.delete(@job)
    end

    def job_id
      Storage.job_id(@job)
    end

    def status
      read[:status]
    end

    def progress
      read[:progress].to_f / read[:total].to_f
    end

    def status_inquiry
      status.to_s.inquiry
    end
  end
end
