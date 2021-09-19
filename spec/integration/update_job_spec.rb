# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

RSpec.describe UpdateJob, type: :job do
  it 'updates a status' do
    job = described_class.new
    result = job.perform_now
    expect(result).to eq({ status: :working, updated: true })
    expect(job.status.to_h).to eq({ status: :completed, updated: true })
  end
end
