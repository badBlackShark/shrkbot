# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Steam volume line", type: :request do
  include_context "plugin config request"

  let(:plugin_path) { server_steam_volume_path(guild.id, app: "1145350") }
  let(:patch_notes) { "Integrations::Steam::PatchNotesPublished" }
  let(:announcements) { "Integrations::Steam::AnnouncementPublished" }
  let(:volume) { Integrations::Volume.new(counts: {patch_notes => 3, announcements => 15}, sample_size: 20) }
  let!(:integrations_plugin) { create(:plugin, key: "integrations", name: "Integrations") }
  let!(:steam_plugin) { create(:plugin, key: "steam", name: "Steam") }

  before do
    post "/auth/discord/callback"
    create(:server_configuration, discord_id: guild.id)
    create(:plugin_activation, server_configuration: config, plugin: integrations_plugin, enabled: true)
    create(:plugin_activation, server_configuration: config, plugin: steam_plugin, enabled: true)
    allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    allow(Feeds::VolumeLookup).to receive(:call).with(Integrations::Steam::NewsWatcher, "1145350").and_return(volume)
    get server_path(guild.id)
  end

  describe "GET /servers/:server_id/steam/volume" do
    subject(:show) { get plugin_path }

    it_behaves_like "a config page that requires a manageable server"

    it "renders the frame with the volume sentence" do
      show

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('turbo-frame id="feed-volume"', "Last 20 posts: 3 patch notes and 15 announcements.")
    end

    context "when Steam did not answer" do
      let(:volume) { nil }

      it "renders an empty frame" do
        show

        expect(response.body).to include('turbo-frame id="feed-volume"')
        expect(response.body).not_to include("Last")
      end
    end
  end
end
