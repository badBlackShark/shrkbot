# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Integrations::Watches::RecordObservation do
  subject(:result) { described_class.call(watch:, events:) }

  let(:watch) { create(:integration_watch) }
  let(:events) { [fresh, stale] }
  let(:fresh) { build(:steam_news_event, watch:, subject_key: "fresh", occurred_at: 1.hour.ago) }
  let(:stale) { build(:steam_news_event, watch:, subject_key: "stale", occurred_at: 49.hours.ago) }

  it "returns the published events" do
    expect(result.value).to eq([fresh])
  end

  it "dispatches the published events to their handlers" do
    expect { result }.to have_enqueued_job(Feeds::AnnounceJob).once.with(fresh)
  end

  it "saves fresh events" do
    result

    expect(Integrations::Event.where(watch:).pluck(:subject_key)).to eq(["fresh"])
  end

  context "on the first poll of a fresh watch" do
    let(:watch) { create(:integration_watch, polled_at: nil) }

    it "saves and dispatches its fresh items instead of withholding the backlog" do
      expect { result }.to have_enqueued_job(Feeds::AnnounceJob).once.with(fresh)
      expect(Integrations::Event.where(watch:).pluck(:subject_key)).to eq(["fresh"])
    end
  end

  context "when one event is new and another was already recorded" do
    let(:events) { [fresh, recorded] }
    let(:fresh) { build(:steam_news_event, watch:, subject_key: "fresh", occurred_at: 1.hour.ago, body: english) }
    let(:recorded) { build(:steam_news_event, watch:, subject_key: "recorded", occurred_at: 1.hour.ago, body: english) }
    let(:english) { "The new update is now available. It fixes several crashes on launch and improves performance on lower-end machines." }

    before do
      create(:steam_news_event, watch:, subject_key: "recorded", occurred_at: 1.hour.ago)
      allow(Integrations::Language).to receive(:detect).and_call_original
    end

    it "detects the language only for the new event" do
      result

      expect(Integrations::Language).to have_received(:detect).once
    end

    it "stores the detected language" do
      result

      expect(fresh.reload.language).to eq("en")
    end
  end

  context "when the watch was failing" do
    let(:watch) do
      create(:integration_watch, failing_since: 30.hours.ago, last_error: "boom")
    end

    it "clears the failure fields" do
      result

      expect(watch.reload).to have_attributes(failing_since: nil, last_error: nil)
    end
  end

  it "stamps polled_at" do
    expect { result }.to change { watch.reload.polled_at }.from(nil)
  end
end
