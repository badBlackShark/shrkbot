# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::Config do
  # Each reads straight from ENV; swap and restore so the suite stays isolated.
  def with_env(key, value)
    original = ENV[key]
    ENV[key] = value
    yield
  ensure
    ENV[key] = original
  end

  describe ".token" do
    it "reads DISCORD_TOKEN from the environment" do
      with_env("DISCORD_TOKEN", "tok-123") { expect(described_class.token).to eq("tok-123") }
    end
  end

  describe ".owner_id" do
    it "reads OWNER_ID from the environment" do
      with_env("OWNER_ID", "9001") { expect(described_class.owner_id).to eq("9001") }
    end
  end

  describe ".owner_guild_id" do
    it "reads OWNER_GUILD_ID from the environment" do
      with_env("OWNER_GUILD_ID", "42") { expect(described_class.owner_guild_id).to eq("42") }
    end
  end

  describe ".web_base_url" do
    it "reads WEB_BASE_URL from the environment" do
      with_env("WEB_BASE_URL", "https://shrkbot.gg") { expect(described_class.web_base_url).to eq("https://shrkbot.gg") }
    end
  end

  describe ".invite_url" do
    it "builds the bare OAuth authorize link so Discord applies the app's default install settings" do
      with_env("CLIENT_ID", "12345") do
        expect(described_class.invite_url).to eq("https://discord.com/oauth2/authorize?client_id=12345")
      end
    end
  end

  describe ".rest_token" do
    subject(:rest_token) { described_class.rest_token }

    before do
      allow(described_class).to receive(:token).and_return(token)
    end

    context "with a raw token" do
      let(:token) { "abc123" }

      it "prefixes with 'Bot ' for the REST API" do
        expect(rest_token).to eq("Bot abc123")
      end
    end

    context "with an already-prefixed token" do
      let(:token) { "Bot abc123" }

      it "doesn't double-prefix" do
        expect(rest_token).to eq("Bot abc123")
      end
    end
  end

  describe ".shard_count" do
    subject(:shard_count) { described_class.shard_count }

    around do |example|
      original = ENV["SHARD_COUNT"]
      ENV["SHARD_COUNT"] = raw
      example.run
      ENV["SHARD_COUNT"] = original
    end

    context "when unset" do
      let(:raw) { nil }

      it { is_expected.to eq(1) }
    end

    context "when set" do
      let(:raw) { "4" }

      it { is_expected.to eq(4) }
    end

    context "when set below 1" do
      let(:raw) { "0" }

      it "floors at 1" do
        expect(shard_count).to eq(1)
      end
    end
  end
end
