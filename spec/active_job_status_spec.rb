# frozen_string_literal: true

require_relative "./spec_helper"

RSpec.describe ActiveJob::Status do
  class BaseJob < ActiveJob::Base
    include ActiveJob::Status

    def perform
    end
  end

  let(:job) { BaseJob.new }

  it "sets job status" do
    expect(job.status).to be_an(ActiveJob::Status::Status)
  end

  it "sets job progress" do
    expect(job.progress).to be_an(ActiveJob::Status::Progress)
  end

  it "instantiates job status with job object" do
    expect(ActiveJob::Status.get(job)).to be_an(ActiveJob::Status::Status)
  end

  it "instantiates job status with job ID" do
    expect(ActiveJob::Status.get(job.job_id)).to be_an(ActiveJob::Status::Status)
  end

  it "sets job status to queued after being enqueued" do
    job = BaseJob.perform_later
    expect(job.status.to_h).to eq({ status: :queued })
  end

  it "sets job status to completed after being performed" do
    job = BaseJob.perform_later
    perform_enqueued_jobs

    expect(job.status.to_h).to eq({ status: :completed })
  end

  pending "sets job status to running while being performed", skip: true do
    class AsyncJob < BaseJob
      queue_adapter = :async

      def perform
        sleep(1)
      end
    end

    job = AsyncJob.perform_later

    expect(job.status.to_h).to eq({ status: :running })
  end

  it "sets job status to failed after an exception is raised" do
    class FailedJob < BaseJob
      def perform
        raise NoMethodError, "Something went wrong"
      end
    end

    job = FailedJob.perform_later
    perform_enqueued_jobs rescue

    expect(job.status.to_h).to eq({ status: :failed })
  end

  it "updates job progress" do
    class ProgressJob < BaseJob
      def perform
        progress.total = 100
        progress.increment(40)
      end
    end

    job = ProgressJob.perform_later
    perform_enqueued_jobs

    expect(job.status.to_h).to include({ progress: 40, total: 100 })
    expect(job.status.progress).to eq(0.4)
  end

  it "updates job status with custom property using []=" do
    class CustomJob < BaseJob
      def perform
        status[:step] = "A"
      end
    end

    job = CustomJob.perform_later
    perform_enqueued_jobs

    expect(job.status.to_h).to include({ step: "A" })
  end

  it "updates job status with multiple properties using .update()" do
    class CustomJob < BaseJob
      def perform
        status.update(step: "B", progress: 25, total: 50)
      end
    end

    job = CustomJob.perform_later
    perform_enqueued_jobs

    expect(job.status.to_h).to include({ step: "B", progress: 25, total: 50 })
    expect(job.status.progress).to eq(0.5)
  end
end
