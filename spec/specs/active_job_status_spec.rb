# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../jobs/test_jobs"

RSpec.describe ActiveJob::Status do
  describe "job status instance" do
    it "assigns a Status to a job" do
      job = BaseJob.new
      expect(job.status).to be_an(ActiveJob::Status::Status)
    end

    it "assigns a Status after enqueuing a job" do
      job = BaseJob.perform_later
      expect(job.status).to be_an(ActiveJob::Status::Status)
    end

    it "retrieves the Status using job instance" do
      job = BaseJob.perform_later
      expect(described_class.get(job)).to be_an(ActiveJob::Status::Status)
    end

    it "retrieves the Status using job ID" do
      job = BaseJob.perform_later
      expect(described_class.get(job.job_id)).to be_an(ActiveJob::Status::Status)
    end
  end

  describe "job status key" do
    it "assigns `queued` status after enqueuing a job" do
      job = BaseJob.perform_later
      expect(job.status.to_h).to eq(status: :queued)
    end

    it "assigns 'working` status while job is performed" do
      job = AsyncJob.perform_later(2)
      sleep(0.1) # Give time to async thread pool to start the job

      expect(job.status.to_h).to eq(status: :working)

      AsyncJob.queue_adapter.shutdown(wait: false)
    end

    it "assigns `completed` status after performing a job" do
      job = BaseJob.perform_later
      perform_enqueued_jobs
      expect(job.status.to_h).to eq(status: :completed)
    end

    it "assigns `failed` status after an exception is raised" do
      job = FailedJob.perform_later

      aggregate_failures do
        expect { perform_enqueued_jobs }.to raise_error(NoMethodError)
        expect(job.status.to_h).to eq(status: :failed)
      end
    end

    context "when status is not included by default" do
      before do
        described_class.options = {includes: []}
      end

      it "doesn't update job status after being enqueued" do
        job = BaseJob.perform_later
        expect(job.status.to_h).to eq({})
      end

      it "doesn't update job status after being performed" do
        job = BaseJob.perform_later
        perform_enqueued_jobs
        expect(job.status.to_h).to eq({})
      end
    end
  end

  describe "job progress" do
    it "assigns a Progress to a job" do
      job = BaseJob.new

      expect(job.progress).to be_an(ActiveJob::Status::Progress)
    end

    it "updates job progress" do
      job = ProgressJob.perform_later
      perform_enqueued_jobs

      aggregate_failures do
        expect(job.status.to_h).to include(progress: 40, total: 100)
        expect(job.status.progress).to eq(0.4)
      end
    end
  end

  describe "job status data" do
    it "updates job status with custom property using []=" do
      job = CustomPropertyJob.perform_later
      perform_enqueued_jobs

      expect(job.status.to_h).to include(step: "A")
    end

    it "updates job status with multiple properties using #update" do
      job = UpdateJob.perform_later
      perform_enqueued_jobs

      expect(job.status.to_h).to include(step: "B", progress: 25, total: 50)
    end

    it "syncs job progress when using #update" do
      job = UpdateJob.perform_later
      job.perform

      aggregate_failures do
        expect(job.progress.progress).to eq(25)
        expect(job.progress.total).to eq(50)
      end
    end

    it "retrieves all job status properties" do
      job = UpdateJob.perform_later
      status = described_class.get(job.job_id)

      expect { perform_enqueued_jobs }
        .to change(status, :to_h)
        .to(status: :completed, step: "B", progress: 25, total: 50)
    end
  end

  describe "throttling" do
    it "updates job status despite throttling using []=" do
      job = ThrottledSettersJob.perform_later
      perform_enqueued_jobs

      expect(job.status.to_h).to include(status: :completed, step: "C", progress: 2, total: 30)
    end

    it "skip status updates due to throttling using .update()" do
      job = ThrottledUpdatesJob.perform_later
      perform_enqueued_jobs

      expect(job.status.to_h).to include(status: :completed)
    end

    it "updates job status despite throttling using .update(.., force: true)" do
      job = ThrottledForcedUpdatesJob.perform_later
      perform_enqueued_jobs

      expect(job.status.to_h).to include(status: :completed, step: "C", progress: 2, total: 30)
    end
  end

  context "when serialized job is included by default" do
    before do
      Timecop.freeze("2022-10-31T00:00:00Z")
      described_class.options = {includes: %i[status serialized_job]}
    end

    it "sets job status to queued after being enqueued" do
      job = BaseJob.perform_later

      expect(job.status.to_h).to eq(
        status: :queued,
        serialized_job: {
          "arguments" => [],
          "enqueued_at" => "2022-10-31T00:00:00Z",
          "exception_executions" => {},
          "executions" => 0,
          "job_class" => "BaseJob",
          "job_id" => job.job_id,
          "locale" => "en",
          "priority" => nil,
          "provider_job_id" => nil,
          "queue_name" => "default",
          "timezone" => nil
        }
      )
    end

    it "sets job status to completed after being performed" do
      job = BaseJob.perform_later
      perform_enqueued_jobs

      expect(job.status.to_h).to eq(
        status: :completed,
        serialized_job: {
          "arguments" => [],
          "enqueued_at" => "2022-10-31T00:00:00Z",
          "exception_executions" => {},
          "executions" => 1,
          "job_class" => "BaseJob",
          "job_id" => job.job_id,
          "locale" => "en",
          "priority" => nil,
          "provider_job_id" => nil,
          "queue_name" => "default",
          "timezone" => nil
        }
      )
    end
  end

  context "when exception is included by default" do
    before do
      described_class.options = {includes: %i[status exception]}
    end

    it "sets job status to failed after an exception is raised" do
      job = FailedJob.perform_later

      aggregate_failures do
        expect { perform_enqueued_jobs }.to raise_error(NoMethodError)
        expect(job.status.to_h).to eq(
          status: :failed,
          exception: {class: "NoMethodError", message: "Something went wrong"}
        )
      end
    end
  end
end
