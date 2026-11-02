# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::EventSub do
  let(:secret) { "test-secret-123" }
  let(:now) { Time.zone.parse("2026-11-02 12:00:00") }
  let(:message_id) { "msg-1" }
  let(:timestamp) { "2026-11-02T12:00:00Z" }
  let(:body) { '{"a":1}' }
  let(:signature) { "sha256=2ddf88a1e4cc708924f6c7522a0c5d32befd97e86eab9ff3ad1de86f76299708" }

  before do
    stub_const("ENV", ENV.to_h.merge("TWITCH_EVENTSUB_SECRET" => secret))
  end

  describe ".configured?" do
    subject(:configured) { described_class.configured? }

    it { is_expected.to be(true) }

    context "with a blank secret" do
      let(:secret) { "" }

      it { is_expected.to be(false) }
    end
  end

  describe ".verified?" do
    subject(:verified) { described_class.verified?(message_id:, timestamp:, body:, signature:, now:) }

    it "accepts the documented HMAC over id + timestamp + body" do
      expect(verified).to be(true)
    end

    context "with a tampered body" do
      let(:body) { '{"a":2}' }

      it { is_expected.to be(false) }
    end

    context "with a different secret" do
      let(:secret) { "other-secret" }

      it { is_expected.to be(false) }
    end

    context "with a nil signature" do
      let(:signature) { nil }

      it { is_expected.to be(false) }
    end

    context "without a configured secret" do
      let(:secret) { "" }

      it { is_expected.to be(false) }
    end

    context "when the timestamp is 11 minutes old" do
      let(:now) { Time.zone.parse("2026-11-02 12:11:00") }

      it { is_expected.to be(false) }
    end

    context "when the timestamp is 11 minutes ahead" do
      let(:now) { Time.zone.parse("2026-11-02 11:49:00") }

      it { is_expected.to be(false) }
    end

    context "with a malformed timestamp" do
      let(:timestamp) { "yesterday" }

      it { is_expected.to be(false) }
    end

    context "with a nanosecond timestamp" do
      let(:timestamp) { "2026-11-02T12:00:00.634234626Z" }
      let(:signature) { "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", secret, message_id + timestamp + body)}" }

      it { is_expected.to be(true) }
    end
  end
end
