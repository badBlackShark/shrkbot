# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Servers::TwilightStruggle tournament authorization", type: :request do
  include_context "discord auth"

  let(:guild) { Bot::Discord::Guild.new(id: 900_000_401, name: "Organiser Server", owner: false, permissions: 0, icon: nil, member_count: 12) }
  let(:config) { ServerConfiguration.find_by(discord_id: guild.id) }
  let(:tournament) { create(:twilight_struggle_tournament) }

  before do
    create(:server_configuration, discord_id: guild.id, name: "Organiser Server")
    create(:bespoke_plugin_grant, server_configuration: config, plugin_key: "twilight_struggle")
    create(:twilight_struggle_tournament_admin, tournament:, discord_id: 12345)
    plugin = create(:plugin, key: "twilight_struggle", name: "Twilight Struggle")
    create(:plugin_activation, server_configuration: config, plugin:, enabled: true)
    allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    post "/auth/discord/callback"
  end

  context "when the organiser opens a tournament they administer" do
    it "renders the destination edit page" do
      get edit_server_twilight_struggle_destination_path(guild.id, tournament)
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the organiser opens a tournament they do not administer" do
    let!(:other_tournament) { create(:twilight_struggle_tournament, name: "RATS Cup 2026") }

    it "is not found" do
      get edit_server_twilight_struggle_destination_path(guild.id, other_tournament)
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when the organiser opens a descendant of a tournament they administer" do
    let!(:child_tournament) { create(:twilight_struggle_tournament, name: "OTSL 2026 Playoffs", parent: tournament) }

    it "renders the destination edit page" do
      get edit_server_twilight_struggle_destination_path(guild.id, child_tournament)
      expect(response).to have_http_status(:ok)
    end
  end

  context "when another tournament is subscribed on the same server" do
    let!(:other_tournament) { create(:twilight_struggle_tournament, name: "RATS Cup 2026") }

    before do
      create(:twilight_struggle_destination, tournament: other_tournament, server_configuration: config, active: true)
    end

    it "keeps it out of the organiser's tournament switcher" do
      get edit_server_twilight_struggle_destination_path(guild.id, tournament)
      expect(response.body).not_to include(other_tournament.name)
    end
  end

  context "when the organiser subscribes to a tournament they do not administer" do
    let!(:other_tournament) { create(:twilight_struggle_tournament, name: "RATS Cup 2026") }

    it "is not found" do
      post server_twilight_struggle_subscriptions_path(guild.id), params: {tournament_id: other_tournament.id}
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when a server admin opens a tournament nobody administers" do
    let(:guild) { Bot::Discord::Guild.new(id: 900_000_402, name: "Admin Server", owner: true, permissions: 0, icon: nil, member_count: 5) }
    let!(:unadministered_tournament) { create(:twilight_struggle_tournament, name: "RATS Cup 2026") }

    it "renders the destination edit page" do
      get edit_server_twilight_struggle_destination_path(guild.id, unadministered_tournament)
      expect(response).to have_http_status(:ok)
    end
  end
end
