# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Twitch category stream sample", type: :request do
  include_context "plugin config request"

  subject(:sample) { get server_twitch_category_streams_path(guild.id, category_id), as: :json }

  let(:plugin_path) { server_twitch_category_streams_path(guild.id, category_id) }
  let(:category_id) { "7" }
  let!(:twitch_plugin) { create(:plugin, key: "twitch", name: "Twitch") }
  let(:rows) { [{viewers: 12, language: "de", login: "liveone"}] }

  before do
    post "/auth/discord/callback"
    create(:server_configuration, discord_id: guild.id)
    create(:plugin_activation, server_configuration: config, plugin: twitch_plugin, enabled: true)
    allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    allow(Feeds::TwitchCategory::StreamSample).to receive(:call).with("7").and_return(rows)
    get server_path(guild.id)
  end

  it "returns the sampled streams as JSON" do
    sample

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq([{"viewers" => 12, "language" => "de", "login" => "liveone"}])
  end

  context "when the category id is not digits" do
    let(:category_id) { "hades" }

    it "answers 404 and samples nothing" do
      sample

      expect(response).to have_http_status(:not_found)
      expect(Feeds::TwitchCategory::StreamSample).not_to have_received(:call)
    end
  end

  context "when Twitch fails" do
    let(:rows) { nil }

    it "answers 503 with no streams" do
      sample

      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body).to eq([])
    end
  end

  context "when the per-user limit is exceeded" do
    before { allow(Rails.cache).to receive(:increment).and_return(9_999) }

    it "answers 429 and samples nothing" do
      sample

      expect(response).to have_http_status(:too_many_requests)
      expect(Feeds::TwitchCategory::StreamSample).not_to have_received(:call)
    end
  end

  context "when the user no longer manages the server" do
    before { allow(Bot::Discord::UserGuilds).to receive(:call).and_return([]) }

    it "samples nothing and sends them to the picker" do
      sample

      expect(response).to redirect_to(servers_path)
      expect(Feeds::TwitchCategory::StreamSample).not_to have_received(:call)
    end
  end
end
