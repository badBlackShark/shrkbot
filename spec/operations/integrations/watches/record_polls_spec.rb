# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Integrations::Watches::RecordPolls do
  include ActiveSupport::Testing::TimeHelpers

  subject(:result) { described_class.call(watches: [failing]) }

  let(:now) { Time.utc(2026, 11, 1, 12, 0, 0) }
  let!(:failing) { create(:integration_watch, failing_since: now - 2.hours, last_error: "Integrations::Unavailable: x", polled_at: now - 10.minutes) }
  let!(:other) { create(:integration_watch, failing_since: now - 2.hours, last_error: "Integrations::Unavailable: x") }

  before { travel_to(now) }

  after { travel_back }

  it "stamps the poll and clears the failure" do
    result

    expect(failing.reload).to have_attributes(polled_at: now, failing_since: nil, last_error: nil)
  end

  it "leaves other watches alone" do
    expect { result }.not_to change { other.reload.failing_since }
  end
end
