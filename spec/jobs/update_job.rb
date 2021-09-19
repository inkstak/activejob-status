# frozen_string_literal: true

class UpdateJob < ActiveJob::Base
  include ActiveJob::Status

  def perform
    status.update(updated: true)
    status.to_h
  end
end
