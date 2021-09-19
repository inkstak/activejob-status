# frozen_string_literal: true

class HelloJob < ActiveJob::Base
  include ActiveJob::Status

  def perform
    true
  end
end
