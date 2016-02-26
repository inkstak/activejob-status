module ActiveJob::Status
  class Sub
    delegate :[], :to_s, :inspect, to: :read
    delegate :queued?, :working?, :completed?, to: :status_inquiry

    def initialize(id)
      @id = id
    end

    def read
      Storage.read(@id)
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
