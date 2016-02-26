module ActiveJob::Status
  class Pub
    delegate :[], :to_s, :inspect, to: :read

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
  end
end
