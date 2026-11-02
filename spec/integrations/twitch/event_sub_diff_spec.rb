# frozen_string_literal: true

require "rails_helper"
require "benchmark"

RSpec.describe Integrations::Twitch::EventSubDiff do
  subject(:diff) { described_class.new(existing:, broadcaster_ids:, callback:, rebuild:) }

  let(:callback) { "https://shrkbot.test/api/twitch/eventsub" }
  let(:broadcaster_ids) { ["1"] }
  let(:rebuild) { false }
  let(:status) { "enabled" }
  let(:existing) { [online, offline, update] }
  let(:online) { subscription("a", "stream.online", "1") }
  let(:offline) { subscription("b", "stream.offline", "1") }
  let(:update) { subscription("c", "channel.update", "2") }

  def subscription(id, type, version, broadcaster_id: "1", status: self.status, callback: self.callback)
    Integrations::Twitch::EventSubSubscription.new(
      id:,
      type:,
      version:,
      status:,
      condition: {"broadcaster_user_id" => broadcaster_id},
      callback:
    )
  end

  context "with nothing subscribed" do
    let(:existing) { [] }

    it "wants every type for every channel" do
      expect(diff.missing).to contain_exactly(
        Integrations::Twitch::EventSubDiff::Wanted.new(type: "stream.online", version: "1", broadcaster_id: "1"),
        Integrations::Twitch::EventSubDiff::Wanted.new(type: "stream.offline", version: "1", broadcaster_id: "1"),
        Integrations::Twitch::EventSubDiff::Wanted.new(type: "channel.update", version: "2", broadcaster_id: "1")
      )
      expect(diff.stale).to be_empty
    end
  end

  context "with the full enabled set" do
    it "changes nothing" do
      expect([diff.stale, diff.missing, diff.revoked]).to all(be_empty)
    end
  end

  context "with a pending verification" do
    let(:status) { "webhook_callback_verification_pending" }

    it "counts as in place" do
      expect([diff.stale, diff.missing]).to all(be_empty)
    end
  end

  context "with another callback" do
    let(:online) { subscription("a", "stream.online", "1", callback: "https://old.test/hook") }

    it "replaces the subscription" do
      expect(diff.stale).to eq([online])
      expect(diff.missing.map(&:type)).to eq(["stream.online"])
    end
  end

  context "with a channel nobody demands" do
    let(:existing) { [online, offline, update, subscription("d", "stream.online", "1", broadcaster_id: "9")] }

    it "deletes only that one" do
      expect(diff.stale.map(&:id)).to eq(["d"])
      expect(diff.missing).to be_empty
    end
  end

  context "with a disabled subscription Twitch will not retry" do
    let(:online) { subscription("a", "stream.online", "1", status: "authorization_revoked") }

    it "replaces it without raising an alert" do
      expect(diff.stale).to eq([online])
      expect(diff.missing.map(&:type)).to eq(["stream.online"])
      expect(diff.revoked).to be_empty
    end
  end

  context "with failures exceeded" do
    let(:online) { subscription("a", "stream.online", "1", status: "notification_failures_exceeded") }

    it "replaces it and reports the revocation" do
      expect(diff.stale).to eq([online])
      expect(diff.missing.map(&:type)).to eq(["stream.online"])
      expect(diff.revoked).to eq([online])
    end
  end

  context "with the old channel.update version" do
    let(:update) { subscription("c", "channel.update", "1") }

    it "replaces it" do
      expect(diff.stale).to eq([update])
      expect(diff.missing.map(&:version)).to eq(["2"])
    end
  end

  context "with a duplicate" do
    let(:existing) { [online, offline, update, subscription("dup", "stream.online", "1")] }

    it "deletes the extra one" do
      expect(diff.stale.map(&:id)).to eq(["dup"])
      expect(diff.missing).to be_empty
    end
  end

  context "when rebuilding" do
    let(:rebuild) { true }

    it "deletes and recreates everything" do
      expect(diff.stale).to match_array(existing)
      expect(diff.missing.size).to eq(3)
    end
  end

  context "with 3,300 channels fully subscribed" do
    subject(:elapsed) { Benchmark.realtime { [diff.stale, diff.missing] } }

    let(:broadcaster_ids) { Array.new(3300) { |index| index.to_s } }
    let!(:existing) do
      broadcaster_ids.flat_map do |broadcaster_id|
        described_class::TYPES.map { |type, version| subscription("#{type}-#{broadcaster_id}", type, version, broadcaster_id:) }
      end
    end

    it "decides within a second" do
      expect(elapsed).to be < 1
    end
  end
end
