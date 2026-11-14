# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Twitch category search", type: :request do
  include_context "plugin config request"

  subject(:search) { get server_twitch_categories_path(guild.id), params: {query: "hades"}, as: :json }

  let(:plugin_path) { server_twitch_categories_path(guild.id) }
  let!(:twitch_plugin) { create(:plugin, key: "twitch", name: "Twitch") }
  let(:results) { [{"id" => "1", "name" => "Hades II"}] }

  before do
    post "/auth/discord/callback"
    create(:server_configuration, discord_id: guild.id)
    create(:plugin_activation, server_configuration: config, plugin: twitch_plugin, enabled: true)
    allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    allow(Feeds::Twitch::CategorySearch).to receive(:call).with("hades").and_return(results)
    get server_path(guild.id)
  end

  it "returns the matches as JSON" do
    search

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(results)
  end

  context "when Twitch fails" do
    let(:results) { nil }

    it "answers 503 with no matches" do
      search

      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body).to eq([])
    end
  end

  context "when the per-user limit is exceeded" do
    before { allow(Rails.cache).to receive(:increment).and_return(9_999) }

    it "answers 429 and searches nothing" do
      search

      expect(response).to have_http_status(:too_many_requests)
      expect(Feeds::Twitch::CategorySearch).not_to have_received(:call)
    end
  end

  context "when the user no longer manages the server" do
    before { allow(Bot::Discord::UserGuilds).to receive(:call).and_return([]) }

    it "searches nothing and sends them to the picker" do
      search

      expect(response).to redirect_to(servers_path)
      expect(Feeds::Twitch::CategorySearch).not_to have_received(:call)
    end
  end
end
