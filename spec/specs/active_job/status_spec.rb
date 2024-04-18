# frozen_string_literal: true

require_relative "../../spec_helper"
require_relative "../../jobs/test_jobs"

RSpec.describe ActiveJob::Status do
  # FIXME: weird error on JRUBY, happening randomly,
  # where keyword arguments are not passed as keyword arguments but with regular
  # arguments
  #
  if RUBY_ENGINE == "jruby" && Gem::Version.new(JRUBY_VERSION) >= Gem::Version.new("9.4")
    def jobs_with(*args, **kwargs)
      super
    rescue ArgumentError
      super(args[0], **args[1]) if kwargs.empty?
    end
  end

  describe "job status instance" do
    it "is assigned when job is initialized" do
      job = BaseJob.new
      expect(job.status).to be_an(ActiveJob::Status::Status)
    end

    it "is assigned when is enqueued" do
      job = BaseJob.perform_later
      expect(job.status).to be_an(ActiveJob::Status::Status)
    end

    it "is retrieved using job instance" do
      job = BaseJob.perform_later
      expect(described_class.get(job)).to be_an(ActiveJob::Status::Status)
    end

    it "is retrieved using job ID" do
      job = BaseJob.perform_later
      expect(described_class.get(job.job_id)).to be_an(ActiveJob::Status::Status)
    end
  end

  describe "job status key" do
    it "is assigned to `queued` after the job is enqueued" do
      job = BaseJob.perform_later
      expect(job.status.to_h).to eq(status: :queued)
    end

    it "is assigned to 'working` while the job is performed" do
      job = AsyncJob.perform_later(2)
      sleep(0.1) # Give time to async thread pool to start the job

      expect(job.status.to_h).to eq(status: :working)

      AsyncJob.queue_adapter.shutdown(wait: false)
    end

    it "is assigned to `completed` after the is performed" do
      job = BaseJob.perform_later
      perform_enqueued_jobs
      expect(job.status.to_h).to eq(status: :completed)
    end

    it "is assigned to `failed` when an exception is raised" do
      job = FailedJob.perform_later

      aggregate_failures do
        expect { perform_enqueued_jobs }.to raise_error(RuntimeError)
        expect(job.status.to_h).to eq(status: :failed)
      end
    end

    context "when status is not included by default" do
      before do
        described_class.options = {includes: []}
      end

      it "isn't assigned after the job is enqueued" do
        job = BaseJob.perform_later
        expect(job.status.to_h).to eq({})
      end

      it "isn't assigned after the job is performed" do
        job = BaseJob.perform_later
        perform_enqueued_jobs
        expect(job.status.to_h).to eq({})
      end
    end
  end

  describe "job progress" do
    it "is assigned to the job instance" do
      job = BaseJob.new
      expect(job.progress).to be_an(ActiveJob::Status::Progress)
    end

    it "is updated from inside the job" do
      job = ProgressJob.perform_later
      perform_enqueued_jobs

      aggregate_failures do
        expect(job.status.to_h).to include(progress: 40, total: 100)
        expect(job.status.progress).to eq(0.4)
      end
    end

    it "reads cache once" do
      job = BaseJob.new

      allow(described_class.store).to receive(:read)
      job.status.progress
      expect(described_class.store).to have_received(:read).once
    end
  end

  describe "job status" do
    it "updates custom property using []=" do
      job = CustomPropertyJob.perform_later
      perform_enqueued_jobs

      expect(job.status.to_h).to include(step: "A")
    end

    it "updates multiple properties using #update" do
      job = UpdateJob.perform_later
      perform_enqueued_jobs

      expect(job.status.to_h).to include(step: "B", progress: 25, total: 50)
    end

    it "updates job progress when using #update" do
      job = UpdateJob.perform_later
      job.perform

      aggregate_failures do
        expect(job.progress.progress).to eq(25)
        expect(job.progress.total).to eq(50)
      end
    end

    it "retrieves all updated properties" do
      job = UpdateJob.perform_later
      status = described_class.get(job.job_id)

      expect { perform_enqueued_jobs }
        .to change(status, :to_h)
        .to(status: :completed, step: "B", progress: 25, total: 50)
    end

    it "updates custom property from the outside using []=" do
      job = BaseJob.perform_later
      status = described_class.get(job.job_id)

      status[:step] = "A"

      expect(job.status.to_h).to include(step: "A")
    end

    it "updates job progress from the outside using []=" do
      job = BaseJob.perform_later
      status = described_class.get(job.job_id)

      status[:progress] = 1
      status[:total] = 5

      expect(job.status.to_h).to include(progress: 1, total: 5)
    end

    it "updates multiple properties from the outside using #update" do
      job = BaseJob.perform_later
      status = described_class.get(job.job_id)

      status.update(step: "C", progress: 24, total: 48)

      expect(job.status.to_h).to include(step: "C", progress: 24, total: 48)
    end
  end

  describe "throttling" do
    it "is ignored when updating status using []=" do
      job = ThrottledSettersJob.perform_later
      perform_enqueued_jobs

      expect(job.status.to_h).to include(status: :completed, step: "C", progress: 2, total: 30)
    end

    it "is limiting updates in a time interval when using #update" do
      job = ThrottledUpdatesJob.perform_later
      perform_enqueued_jobs

      expect(job.status.to_h).to include(status: :completed)
    end

    it "is bypassed when using :force parameter in #update" do
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
          "enqueued_at" => "2022-10-31T00:00:00.000000000Z",
          "exception_executions" => {},
          "executions" => 0,
          "job_class" => "BaseJob",
          "job_id" => job.job_id,
          "locale" => "en",
          "priority" => nil,
          "provider_job_id" => nil,
          "queue_name" => "default",
          "scheduled_at" => nil,
          "timezone" => nil
        }.tap { |hash|
          # FIXME: comparing Gem::Version with String doesn't work in ruby 3.0
          # After removing support for 3.0, we could do
          #   ActiveJob.version < "7.1"
          #
          if ActiveJob.version < Gem::Version.new("7.1")
            hash["enqueued_at"] = "2022-10-31T00:00:00Z"
            hash.delete("scheduled_at")
          end
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
          "enqueued_at" => "2022-10-31T00:00:00.000000000Z",
          "exception_executions" => {},
          "executions" => 1,
          "job_class" => "BaseJob",
          "job_id" => job.job_id,
          "locale" => "en",
          "priority" => nil,
          "provider_job_id" => nil,
          "queue_name" => "default",
          "scheduled_at" => nil,
          "timezone" => nil
        }.tap { |hash|
          if ActiveJob.version < Gem::Version.new("7.1")
            hash["enqueued_at"] = "2022-10-31T00:00:00Z"
            hash.delete("scheduled_at")
          end
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
        expect { perform_enqueued_jobs }.to raise_error(RuntimeError)
        expect(job.status.to_h).to eq(
          status: :failed,
          exception: {class: "RuntimeError", message: "Something went wrong"}
        )
      end
    end

    it "returns origin message from failure, without DidYouMean suggestions" do
      job = MethodErrorJob.perform_later

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
