# frozen_string_literal: true

class RescueJob < ActiveJob::Base
  include ActiveJob::Status

  def perform
    raise NoMethodError, "Something went wrong"
  end
end
