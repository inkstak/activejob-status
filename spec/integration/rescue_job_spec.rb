# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

RSpec.describe RescueJob, type: :job do
  it 'runs a job that fails' do
    expect { described_class.perform_now }.to raise_error(NoMethodError)

  end
end
