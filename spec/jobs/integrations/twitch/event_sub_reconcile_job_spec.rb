# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::EventSubReconcileJob do
  subject(:perform) { described_class.perform_now(rebuild:) }

  let(:watcher) { "Integrations::Twitch::ChannelWatcher" }
  let(:callback) { "https://shrkbot.test/api/twitch/eventsub" }
  let(:rebuild) { false }
  let(:existing) { [] }
  let(:subscriptions) { instance_double(Integrations::Twitch::EventSubSubscriptions, all: existing, create: nil, destroy: nil) }
  let(:secret) { "s3cret" }
  let(:base_url) { "https://shrkbot.test" }
  let!(:watch) { create(:integration_watch, watcher:, external_id: "1", name: "Live One") }
  let(:demanded) { [watch] }

  def subscription(id, type, version, status: "enabled", broadcaster_id: "1")
    Integrations::Twitch::EventSubSubscription.new(
      id:,
      type:,
      version:,
      status:,
      condition: {"broadcaster_user_id" => broadcaster_id},
      callback:
    )
  end

  before do
    stub_const("ENV", ENV.to_h.merge("TWITCH_EVENTSUB_SECRET" => secret, "WEB_BASE_URL" => base_url))
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    allow(Integrations::Twitch::Client).to receive(:configured?).and_return(true)
    allow(Integrations::Twitch::EventSubSubscriptions).to receive(:new).and_return(subscriptions)
    allow(Integrations::Watch).to receive(:demanded) { Integrations::Watch.where(id: demanded.map(&:id)) }
    allow(Rails.logger).to receive(:warn)
  end

  context "without a webhook secret" do
    let(:secret) { "" }

    it "asks Twitch for nothing" do
      perform

      expect(subscriptions).not_to have_received(:all)
    end
  end

  context "with a plain http base URL" do
    let(:base_url) { "http://localhost:3000" }

    it "asks Twitch for nothing" do
      perform

      expect(subscriptions).not_to have_received(:all)
    end
  end

  describe "concurrency" do
    it "gives every run the same key, so an overlapping run is discarded" do
      expect(described_class.new.concurrency_key).to eq(described_class.new.concurrency_key)
      expect(described_class).to have_attributes(concurrency_on_conflict: :discard)
    end
  end

  context "with a demanded channel and no subscriptions" do
    it "creates the three subscriptions against the receiver URL" do
      perform

      expect(subscriptions).to have_received(:create).with(type: "stream.online", version: "1", condition: {broadcaster_user_id: "1"}, callback:)
      expect(subscriptions).to have_received(:create).with(type: "stream.offline", version: "1", condition: {broadcaster_user_id: "1"}, callback:)
      expect(subscriptions).to have_received(:create).with(type: "channel.update", version: "2", condition: {broadcaster_user_id: "1"}, callback:)
    end
  end

  context "with a subscription for an undemanded channel" do
    let(:existing) do
      [
        subscription("a", "stream.online", "1"),
        subscription("b", "stream.offline", "1"),
        subscription("c", "channel.update", "2"),
        subscription("old", "stream.online", "1", broadcaster_id: "9")
      ]
    end

    it "deletes it and creates nothing" do
      perform

      expect(subscriptions).to have_received(:destroy).with("old").once
      expect(subscriptions).not_to have_received(:create)
    end
  end

  context "when rebuilding" do
    let(:rebuild) { true }
    let(:existing) do
      [subscription("a", "stream.online", "1"), subscription("b", "stream.offline", "1"), subscription("c", "channel.update", "2")]
    end

    it "deletes every existing subscription and creates them again" do
      perform

      expect(subscriptions).to have_received(:destroy).exactly(3).times
      expect(subscriptions).to have_received(:create).exactly(3).times
    end
  end

  context "when creating fails" do
    before do
      allow(subscriptions).to receive(:create).and_raise(Integrations::Error, "boom")
    end

    it "tells the owner once, grouped by error" do
      expect { perform }.to have_enqueued_job(Integrations::Twitch::ReportEventSubJob)
        .with(["Creating 3 subscriptions failed (first: stream.online for channel 1): Integrations::Error: boom"])
        .once
    end

    it "does not repeat the alert on the next run" do
      described_class.perform_now

      expect { perform }.not_to have_enqueued_job(Integrations::Twitch::ReportEventSubJob)
    end
  end

  context "when Twitch revoked a subscription for failures" do
    let(:existing) do
      [
        subscription("a", "stream.online", "1", status: "notification_failures_exceeded"),
        subscription("b", "stream.offline", "1"),
        subscription("c", "channel.update", "2")
      ]
    end

    it "recreates it and tells the owner" do
      expect { perform }.to have_enqueued_job(Integrations::Twitch::ReportEventSubJob)
        .with(["Twitch revoked 1 subscription: notification_failures_exceeded."])

      expect(subscriptions).to have_received(:destroy).with("a")
      expect(subscriptions).to have_received(:create).with(hash_including(type: "stream.online")).once
    end
  end

  context "when Twitch rate limits a create" do
    before do
      allow(subscriptions).to receive(:create).and_raise(Integrations::RateLimited.new("slow down", retry_after: 30))
    end

    it "stops the run and logs it" do
      expect { perform }.not_to have_enqueued_job(Integrations::Twitch::ReportEventSubJob)

      expect(subscriptions).to have_received(:create).once
      expect(Rails.logger).to have_received(:warn).with(/EventSub reconcile failed: Integrations::RateLimited/)
    end
  end

  context "when listing subscriptions fails" do
    before do
      allow(subscriptions).to receive(:all).and_raise(Integrations::Unavailable, "503")
    end

    it "logs and changes nothing" do
      perform

      expect(subscriptions).not_to have_received(:create)
      expect(Rails.logger).to have_received(:warn).with(/EventSub reconcile failed: Integrations::Unavailable: 503/)
    end
  end
end
