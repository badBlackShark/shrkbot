# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Integrations::Watches::RecordObservation do
  subject(:result) { described_class.call(watch:, events:) }

  let(:watch) { create(:integration_watch, primed_at:) }
  let(:primed_at) { 1.day.ago }
  let(:events) { [fresh, stale] }
  let(:fresh) { build(:steam_news_event, watch:, subject_key: "fresh", occurred_at: 1.hour.ago) }
  let(:stale) { build(:steam_news_event, watch:, subject_key: "stale", occurred_at: 49.hours.ago) }

  it "returns the published events" do
    expect(result.value).to eq([fresh])
  end

  it "saves fresh unseen events" do
    result

    expect(Integrations::Event.where(watch:).pluck(:subject_key)).to eq(["fresh"])
  end

  it "records fresh unseen items as seen and never writes stale ones" do
    result

    expect(watch.seen_items.pluck(:external_id)).to eq(["fresh"])
  end

  context "when the watch has never been polled" do
    let(:primed_at) { nil }

    it "saves nothing but marks every fresh item seen" do
      result

      expect(Integrations::Event.count).to eq(0)
      expect(watch.seen_items.pluck(:external_id)).to eq(["fresh"])
    end

    it "stamps primed_at" do
      expect { result }.to change { watch.reload.primed_at }.from(nil)
    end
  end

  context "when an item was seen before" do
    before do
      create(:integration_seen_item, watch:, external_id: "fresh")
    end

    it "skips it without duplicating the ledger entry" do
      result

      expect(Integrations::Event.count).to eq(0)
      expect(watch.seen_items.where(external_id: "fresh").count).to eq(1)
    end
  end

  context "when a fresh event is invalid" do
    let(:events) { [fresh, invalid] }
    let(:invalid) { build(:steam_news_event, watch:, subject_key: "blank", occurred_at: 1.hour.ago, title: "") }

    it "drops it, publishes the rest and still marks it seen" do
      expect(result.value).to eq([fresh])
      expect(watch.seen_items.pluck(:external_id)).to contain_exactly("fresh", "blank")
    end
  end

  context "when every item was seen before" do
    before do
      create(:integration_seen_item, watch:, external_id: "fresh")
      create(:integration_seen_item, watch:, external_id: "stale")
    end

    it "publishes nothing and leaves the ledger as it was" do
      expect(result.value).to be_empty
      expect(watch.seen_items.count).to eq(2)
    end
  end

  context "when the watch was failing" do
    let(:watch) do
      create(:integration_watch, primed_at:, failing_since: 30.hours.ago, last_error: "boom")
    end

    it "clears the failure fields" do
      result

      expect(watch.reload).to have_attributes(failing_since: nil, last_error: nil)
    end
  end

  it "stamps polled_at" do
    expect { result }.to change { watch.reload.polled_at }.from(nil)
  end

  it "keeps the freshness window shorter than ledger retention, so an item whose seen row was pruned comes back stale" do
    expect(described_class::FRESHNESS_WINDOW).to be < Ops::Integrations::Prune::RETENTION
  end
end
