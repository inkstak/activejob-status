# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../jobs/test_jobs"

RSpec.describe ActiveJob::Status do
  let(:job) { BaseJob.new }

  it "sets job status" do
    expect(job.status).to be_an(ActiveJob::Status::Status)
  end

  it "sets job progress" do
    expect(job.progress).to be_an(ActiveJob::Status::Progress)
  end

  it "instantiates job status with job object" do
    expect(described_class.get(job)).to be_an(ActiveJob::Status::Status)
  end

  it "instantiates job status with job ID" do
    expect(described_class.get(job.job_id)).to be_an(ActiveJob::Status::Status)
  end

  it "sets job status to queued after being enqueued" do
    job = BaseJob.perform_later

    expect(job.status.to_h).to eq(status: :queued)
  end

  it "sets job status to completed after being performed" do
    job = BaseJob.perform_later
    perform_enqueued_jobs

    expect(job.status.to_h).to eq(status: :completed)
  end

  pending "sets job status to running while being performed", skip: true do
    job = AsyncJob.perform_later

    expect(job.status.to_h).to eq(status: :running)
  end

  it "sets job status to failed after an exception is raised" do
    job = FailedJob.perform_later

    expect { perform_enqueued_jobs }.to raise_error(NoMethodError)
    expect(job.status.to_h).to eq(status: :failed)
  end

  it "updates job progress" do
    job = ProgressJob.perform_later
    perform_enqueued_jobs

    expect(job.status.to_h).to include(progress: 40, total: 100)
    expect(job.status.progress).to eq(0.4)
  end

  it "updates job status with custom property using []=" do
    job = CustomPropertyJob.perform_later
    perform_enqueued_jobs

    expect(job.status.to_h).to include(step: "A")
  end

  it "updates job status with multiple properties using .update()" do
    job = UpdateJob.perform_later
    perform_enqueued_jobs

    expect(job.status.to_h).to include(step: "B", progress: 25, total: 50)
  end

  it "internally sync job progress when updating it with .update()" do
    job = UpdateJob.new
    job.perform

    expect(job.progress.progress).to eq(25)
    expect(job.progress.total).to eq(50)
  end

  it "retrieves all job status properties remotely" do
    job = UpdateJob.perform_later
    status = described_class.get(job.job_id)

    expect { perform_enqueued_jobs }
      .to change(status, :to_h)
      .to(status: :completed, step: "B", progress: 25, total: 50)
  end

  context "with throttle mechanism" do
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

  context "with #job included as an option" do
    before do
      described_class.options = {includes: %i[status serialized_job]}
    end

    it "sets job status to queued after being enqueued" do
      job = BaseJob.perform_later

      expect(job.status.to_h).to eq(status: :queued, serialized_job: job.serialize)
    end

    it "sets job status to completed after being performed" do
      job = BaseJob.perform_later
      perform_enqueued_jobs

      expect(job.status.to_h).to eq(status: :completed, serialized_job: job.serialize)
    end
  end

  context "with #exception included as an option" do
    before do
      described_class.options = {includes: %i[status exception]}
    end

    it "sets job status to failed after an exception is raised" do
      job = FailedJob.perform_later

      expect { perform_enqueued_jobs }.to raise_error(NoMethodError)
      expect(job.status.to_h).to eq(status: :failed, exception: "Something went wrong")
    end
  end
end
