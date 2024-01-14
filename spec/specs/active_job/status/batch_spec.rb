# frozen_string_literal: true

require_relative "../../../spec_helper"
require_relative "../../../jobs/test_jobs"

RSpec.describe ActiveJob::Status::Batch do
  describe "#status" do
    it "returns queued when all jobs are queued" do
      first_job = BaseJob.perform_later
      second_job = BaseJob.perform_later
      batch = described_class.new(first_job, second_job)

      ActiveJob::Status.get(first_job).update(status: :queued)
      ActiveJob::Status.get(second_job).update(status: :queued)

      expect(batch.status).to eq(:queued)
    end

    it "returns failed when one job is failed" do
      first_job = BaseJob.perform_later
      second_job = BaseJob.perform_later
      batch = described_class.new(first_job, second_job)

      ActiveJob::Status.get(first_job).update(status: :failed)
      ActiveJob::Status.get(second_job).update(status: :completed)

      expect(batch.status).to eq(:failed)
    end

    it "returns completed when all jobs are completed" do
      first_job = BaseJob.perform_later
      second_job = BaseJob.perform_later
      batch = described_class.new(first_job, second_job)

      ActiveJob::Status.get(first_job).update(status: :completed)
      ActiveJob::Status.get(second_job).update(status: :completed)

      expect(batch.status).to eq(:completed)
    end

    it "returns working in other cases" do
      first_job = BaseJob.perform_later
      second_job = BaseJob.perform_later
      batch = described_class.new(first_job, second_job)

      ActiveJob::Status.get(first_job).update(status: :queued)
      ActiveJob::Status.get(second_job).update(status: :working)

      expect(batch.status).to eq(:working)
    end
  end
end
