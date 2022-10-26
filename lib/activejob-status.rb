# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/hash"
require "activejob-status/storage"
require "activejob-status/status"
require "activejob-status/progress"
require "activejob-status/throttle"

module ActiveJob
  module Status
    extend ActiveSupport::Concern

    DEFAULT_OPTIONS = {
      expires_in: 60 * 30,
      throttle_interval: 0,
      includes: {}
    }.freeze

    included do
      before_enqueue do |job|
        job.status[:status] = :queued
        job.status[:serialized_job] = job.serialize if ActiveJob::Status.options.fetch(:includes, []).include?(:serialized_job)
      end

      before_perform { |job| job.status[:status] = :working }
      after_perform { |job| job.status[:status] = :completed }

      rescue_from(Exception) do |e|
        if ActiveJob::Status.options.fetch(:includes, []).include?(:exception)
          status.update(status: :failed, exception: e.message)
        else
          status.update(status: :failed)
        end
        raise e
      end
    end

    def status
      @status ||= Status.new(self)
    end

    def progress
      @progress ||= Progress.new(self)
    end

    class << self
      def options=(options)
        options.assert_valid_keys(*DEFAULT_OPTIONS.keys)
        @@options = DEFAULT_OPTIONS.merge(options)
      end

      def options
        @@options ||= DEFAULT_OPTIONS
      end

      def store=(store)
        store = ActiveSupport::Cache.lookup_store(*store) if store.is_a?(Array) || store.is_a?(Symbol)
        @@store = store
      end

      def store
        @@store ||= (defined?(Rails) && Rails.cache)
      end

      def get(id)
        Status.new(id)
      end
    end
  end
end
