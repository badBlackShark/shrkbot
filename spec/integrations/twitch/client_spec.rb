# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::Client do
  include ActiveSupport::Testing::TimeHelpers

  subject(:get_json) do
    client.get_json("/streams", params:, status_errors:) { |body| body.fetch("answer") }
  end

  let(:client) { described_class.new(token:) }
  let(:token) { instance_double(Integrations::Twitch::AppToken, value: "tok", invalidate!: nil) }
  let(:params) { {user_id: %w[1 2]} }
  let(:status_errors) { {404 => Integrations::Unavailable} }
  let(:headers) { {"Client-Id" => "the-id", "Authorization" => "Bearer tok"} }

  before do
    stub_const("ENV", ENV.to_h.merge("TWITCH_CLIENT_ID" => "the-id", "TWITCH_CLIENT_SECRET" => "the-secret"))
    allow(Integrations::Http).to receive(:get_json) { |*_args, **_kwargs, &block| block.call({"answer" => 42}) }
    allow(Integrations::Http).to receive(:post_json) { |*_args, **_kwargs, &block| block.call({"answer" => 43}) }
    allow(Integrations::Http).to receive(:delete).and_return(nil)
  end

  describe "#get_json" do
    it "requests the path on the Helix host with the app headers, params and status_errors" do
      get_json

      expect(Integrations::Http).to have_received(:get_json).with(
        "https://api.twitch.tv/helix/streams",
        params: {user_id: %w[1 2]},
        headers:,
        status_errors: {403 => Integrations::Error, 404 => Integrations::Unavailable}
      )
    end

    it "hands the caller's block to Http and returns its value" do
      expect(get_json).to eq(42)
    end
  end

  describe "#post_json" do
    subject(:post_json) do
      client.post_json("/eventsub/subscriptions", body: {type: "x"}, status_errors:) { |body| body.fetch("answer") }
    end

    it "posts the body to the path with the app headers" do
      post_json

      expect(Integrations::Http).to have_received(:post_json).with(
        "https://api.twitch.tv/helix/eventsub/subscriptions",
        body: {type: "x"},
        headers:,
        status_errors: {403 => Integrations::Error, 404 => Integrations::Unavailable}
      )
    end

    it "returns the block's value" do
      expect(post_json).to eq(43)
    end
  end

  describe "#delete" do
    subject(:delete) { client.delete("/eventsub/subscriptions", params: {id: "abc"}, status_errors:) }

    it "deletes the path with the app headers, params and status_errors" do
      delete

      expect(Integrations::Http).to have_received(:delete).with(
        "https://api.twitch.tv/helix/eventsub/subscriptions",
        params: {id: "abc"},
        headers:,
        status_errors: {403 => Integrations::Error, 404 => Integrations::Unavailable}
      )
    end
  end

  context "when Twitch rejects the token once" do
    let(:token) { instance_double(Integrations::Twitch::AppToken, invalidate!: nil) }
    let(:calls) { [] }

    before do
      allow(token).to receive(:value).and_return("stale", "fresh")
      allow(Integrations::Http).to receive(:get_json) do |*_args, **kwargs, &block|
        calls << kwargs.fetch(:headers).fetch("Authorization")
        raise Integrations::Unauthorized if calls.one?

        block.call({"answer" => 42})
      end
    end

    it "drops the token and retries with a fresh one" do
      expect(get_json).to eq(42)
      expect(calls).to eq(["Bearer stale", "Bearer fresh"])
      expect(token).to have_received(:invalidate!).once
    end
  end

  context "when Twitch rejects the fresh token too" do
    before do
      allow(Integrations::Http).to receive(:get_json).and_raise(Integrations::Unauthorized)
    end

    it "raises after exactly one retry" do
      expect { get_json }.to raise_error(Integrations::Unauthorized)
      expect(Integrations::Http).to have_received(:get_json).twice
      expect(token).to have_received(:invalidate!).once
    end
  end

  context "when the token itself cannot be fetched" do
    before do
      allow(token).to receive(:value).and_raise(Integrations::Unauthorized)
    end

    it "raises without dropping the token or fetching it again" do
      expect { get_json }.to raise_error(Integrations::Unauthorized)
      expect(token).to have_received(:value).once
      expect(token).not_to have_received(:invalidate!)
    end
  end

  context "when Twitch is rate limited" do
    let(:now) { Time.utc(2026, 10, 31, 12, 0, 0) }
    let(:limited) { Integrations::RateLimited.new("api.twitch.tv responded 429", retry_after:, headers: {"ratelimit-reset" => [reset.to_s]}) }
    let(:retry_after) { nil }
    let(:reset) { now.to_i + 45 }

    before do
      travel_to(now)
      allow(Integrations::Http).to receive(:get_json).and_raise(limited)
    end

    after { travel_back }

    it "waits until Twitch's Ratelimit-Reset" do
      expect { get_json }.to raise_error(Integrations::RateLimited) { |error| expect(error.retry_after).to eq(45) }
    end

    context "when the reset is already past" do
      let(:reset) { now.to_i - 10 }

      it "waits 0, never a negative time" do
        expect { get_json }.to raise_error(Integrations::RateLimited) { |error| expect(error.retry_after).to eq(0) }
      end
    end

    context "when the response already says how long to wait" do
      let(:retry_after) { 7 }

      it "keeps that wait" do
        expect { get_json }.to raise_error(Integrations::RateLimited) { |error| expect(error.retry_after).to eq(7) }
      end
    end

    context "without a reset header" do
      let(:limited) { Integrations::RateLimited.new("api.twitch.tv responded 429") }

      it "has no wait" do
        expect { get_json }.to raise_error(Integrations::RateLimited) { |error| expect(error.retry_after).to be_nil }
      end
    end
  end

  describe "#get_all" do
    subject(:get_all) { client.get_all("/clips", params: {first: 100}) { |body| body.fetch("data") } }

    let(:pages) do
      {
        nil => {"data" => [1, 2], "pagination" => {"cursor" => "next"}},
        "next" => {"data" => [3], "pagination" => {}}
      }
    end

    before do
      allow(Integrations::Http).to receive(:get_json) do |_url, params:, **_kwargs, &block|
        block.call(pages.fetch(params[:after]))
      end
    end

    it "follows the cursor and joins the pages" do
      expect(get_all).to eq([1, 2, 3])
    end

    it "keeps the caller's params on every page" do
      get_all

      expect(Integrations::Http).to have_received(:get_json).with(anything, hash_including(params: {first: 100}))
      expect(Integrations::Http).to have_received(:get_json).with(anything, hash_including(params: {first: 100, after: "next"}))
    end
  end

  context "when Twitch is unavailable" do
    before do
      allow(Integrations::Http).to receive(:get_json).and_raise(Integrations::Unavailable)
    end

    it "raises without retrying or touching the token" do
      expect { get_json }.to raise_error(Integrations::Unavailable)
      expect(Integrations::Http).to have_received(:get_json).once
      expect(token).not_to have_received(:invalidate!)
    end
  end

  describe ".configured?" do
    subject(:configured) { described_class.configured? }

    context "with both credentials" do
      it { is_expected.to be(true) }
    end

    context "without a secret" do
      before do
        stub_const("ENV", ENV.to_h.merge("TWITCH_CLIENT_SECRET" => nil))
      end

      it { is_expected.to be(false) }
    end

    context "with a blank client id" do
      before do
        stub_const("ENV", ENV.to_h.merge("TWITCH_CLIENT_ID" => ""))
      end

      it { is_expected.to be(false) }
    end
  end
end
