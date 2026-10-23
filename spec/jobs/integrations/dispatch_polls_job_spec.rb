# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::DispatchPollsJob do
  subject(:perform) { described_class.perform_now("Integrations::Steam::NewsWatcher") }

  let!(:due) { create(:integration_watch) }
  let!(:broken_just_polled) { create(:integration_watch, failing_since: 25.hours.ago, polled_at: 10.minutes.ago) }

  before do
    create(:integration_watch, watcher: "Integrations::Other::Watcher")
    allow(ActiveJob).to receive(:perform_all_later)
  end

  it "enqueues a poll for each due watch of that watcher only" do
    perform

    expect(ActiveJob).to have_received(:perform_all_later) do |jobs|
      expect(jobs.map { |job| job.arguments.first }).to eq([due])
    end
  end
end
