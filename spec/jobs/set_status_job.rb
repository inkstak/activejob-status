# frozen_string_literal: true

class SetStatusJob < ActiveJob::Base
  include ActiveJob::Status

  def perform
    status[:updated] = true
    status.to_h
  end
end
