# frozen_string_literal: true

require "rails_helper"

RSpec.describe SentryBreadcrumbScrubber do
  subject(:scrubbed) { described_class.call(breadcrumb, {}) }

  let(:category) { "net.http" }
  let(:data) { {status: 200, method: "POST", url:} }
  let(:breadcrumb) { Sentry::Breadcrumb.new(category:, data:) }
  let(:url) { "https://discord.com/api/v10/channels/1/messages" }

  context "with a Discord interaction callback" do
    let(:url) { "https://discord.com/api/v10/interactions/123/secret-token/callback" }

    it "replaces the token segment" do
      expect(scrubbed.data[:url]).to eq("https://discord.com/api/v10/interactions/123/[Filtered]/callback")
    end
  end

  context "with a webhook follow-up" do
    let(:url) { "https://discord.com/api/v10/webhooks/456/secret-token/messages/@original" }

    it "replaces the token segment" do
      expect(scrubbed.data[:url]).to eq("https://discord.com/api/v10/webhooks/456/[Filtered]/messages/@original")
    end
  end

  context "with a Steam URL carrying the API key" do
    let(:category) { "http" }
    let(:url) { "https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?key=abc123&appid=10" }
    let(:data) { {status: 200, method: "GET", url:, query: "key=abc123&appid=10"} }

    it "drops the query string from the URL" do
      expect(scrubbed.data[:url]).to eq("https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/")
    end

    it "drops the query data" do
      expect(scrubbed.data).not_to have_key(:query)
    end
  end

  context "with a Twitch URL carrying a query and a request body" do
    let(:url) { "https://api.twitch.tv/helix/streams?user_id=1" }
    let(:data) { {status: 200, method: "POST", url:, query: "user_id=1", body: "{\"secret\":1}"} }

    it "keeps only the request line and status" do
      expect(scrubbed.data).to eq(status: 200, method: "POST", url: "https://api.twitch.tv/helix/streams")
    end
  end

  context "with a plain URL" do
    it "leaves it untouched" do
      expect(scrubbed.data[:url]).to eq(url)
    end
  end

  context "with a breadcrumb from another source" do
    let(:category) { "active_support" }
    let(:data) { {query: "kept", url: "https://x.test/interactions/1/token/callback"} }

    it "returns the data unchanged" do
      expect(scrubbed.data).to eq(query: "kept", url: "https://x.test/interactions/1/token/callback")
    end
  end
end
