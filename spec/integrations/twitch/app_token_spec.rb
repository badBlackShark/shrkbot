# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::AppToken do
  include ActiveSupport::Testing::TimeHelpers

  subject(:value) { token.value }

  let(:token) { described_class.new }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:expires_in) { 5_184_000 }

  before do
    stub_const("ENV", ENV.to_h.merge("TWITCH_CLIENT_ID" => "the-id", "TWITCH_CLIENT_SECRET" => "the-secret"))
    allow(Rails).to receive(:cache).and_return(cache)
    allow(Integrations::Http).to receive(:post_form) do |*_args, **_kwargs, &block|
      block.call({"access_token" => "fresh", "expires_in" => expires_in, "token_type" => "bearer"})
    end
  end

  it "requests a client-credentials token, treating 400 and 403 as bad credentials" do
    value

    expect(Integrations::Http).to have_received(:post_form).with(
      "https://id.twitch.tv/oauth2/token",
      form: {client_id: "the-id", client_secret: "the-secret", grant_type: "client_credentials"},
      status_errors: {400 => Integrations::Unauthorized, 403 => Integrations::Unauthorized}
    )
  end

  it "returns the access token" do
    expect(value).to eq("fresh")
  end

  it "caches the token for a day less than it lives" do
    value

    travel_to(Time.current + expires_in - 1.day.to_i - 60) do
      expect(cache.read(described_class::CACHE_KEY)).to eq("fresh")
    end
    travel_to(Time.current + expires_in - 1.day.to_i + 60) do
      expect(cache.read(described_class::CACHE_KEY)).to be_nil
    end
  end

  context "when the cache already holds a token" do
    before do
      cache.write(described_class::CACHE_KEY, "cached")
    end

    it "returns it without a request" do
      expect(value).to eq("cached")
      expect(Integrations::Http).not_to have_received(:post_form)
    end
  end

  context "when the cache stores nothing" do
    let(:cache) { ActiveSupport::Cache::NullStore.new }

    it "still asks Twitch only once per instance" do
      token.value
      token.value

      expect(Integrations::Http).to have_received(:post_form).once
    end
  end

  describe "#invalidate!" do
    before do
      token.value
      token.invalidate!
    end

    it "drops the cached token" do
      expect(cache.read(described_class::CACHE_KEY)).to be_nil
    end

    it "makes the next value fetch a new token" do
      token.value

      expect(Integrations::Http).to have_received(:post_form).twice
    end
  end
end
