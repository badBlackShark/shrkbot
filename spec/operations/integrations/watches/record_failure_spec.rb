# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Integrations::Watches::RecordFailure do
  subject(:result) { described_class.call(watch:, error: Integrations::Unavailable.new("api.steampowered.com responded 503")) }

  let(:watch) { create(:integration_watch, failing_since:) }
  let(:failing_since) { nil }

  it "starts the failure window" do
    expect { result }.to change { watch.reload.failing_since }.from(nil)
  end

  it "stores the error message" do
    result

    expect(watch.reload.last_error).to eq("api.steampowered.com responded 503")
  end

  it "stamps polled_at" do
    expect { result }.to change { watch.reload.polled_at }.from(nil)
  end

  context "when the watch was already failing" do
    let(:failing_since) { 3.hours.ago.change(usec: 0) }

    it "keeps the original start" do
      result

      expect(watch.reload.failing_since).to eq(failing_since)
    end
  end
end
