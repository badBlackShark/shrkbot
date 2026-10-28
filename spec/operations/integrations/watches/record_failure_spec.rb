# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Integrations::Watches::RecordFailure do
  subject(:result) { described_class.call(watch:, error: Integrations::Unavailable.new("api.steampowered.com responded 503")) }

  let(:watch) { create(:integration_watch, failing_since:, polled_at:) }
  let(:failing_since) { nil }
  let(:polled_at) { nil }

  it "starts the failure window" do
    expect { result }.to change { watch.reload.failing_since }.from(nil)
  end

  it "stores the error class and message" do
    result

    expect(watch.reload.last_error).to eq("Integrations::Unavailable: api.steampowered.com responded 503")
  end

  it "stamps polled_at" do
    expect { result }.to change { watch.reload.polled_at }.from(nil)
  end

  context "when the watch was already failing and one hourly tick was dropped since" do
    let(:failing_since) { 5.hours.ago.change(usec: 0) }
    let(:polled_at) { 2.hours.ago - 5.minutes }

    it "keeps the original start" do
      result

      expect(watch.reload.failing_since).to eq(failing_since)
    end
  end

  context "when the watch was failing but not polled for longer than the dormant window" do
    let(:failing_since) { 3.days.ago }
    let(:polled_at) { 5.hours.ago }

    it "starts a new failure window" do
      result

      expect(watch.reload.failing_since).to be_within(1.minute).of(Time.current)
    end
  end
end
