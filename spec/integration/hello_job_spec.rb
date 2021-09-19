# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

RSpec.describe HelloJob, type: :job do
  it 'runs a job' do
    expect(described_class.perform_now).to eq(true)
  end
end
