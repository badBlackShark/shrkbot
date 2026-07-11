# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Role set reposts", type: :request do
  include_context "discord auth"

  let(:guild) { Bot::Discord::Guild.new(id: 900_000_001, name: "Dev Refuge", owner: true, permissions: 0, icon: nil, member_count: 5) }
  let(:config) { ServerConfiguration.find_by(discord_id: guild.id) }
  let(:turbo) { {headers: {"Accept" => "text/vnd.turbo-stream.html"}} }

  before do
    allow(Bot::ConfigBus).to receive(:repost_roles)
    allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
  end

  context "when signed out" do
    it "redirects to the sign-in page" do
      post server_role_set_repost_path(900_000_001, "rst_fake")
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in" do
    let!(:roles_plugin) { create(:plugin, key: "roles", name: "Roles") }

    before do
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id, bot_role_position: 100)
      create(:server_channel, server_configuration: config, name: "get-roles", discord_id: 111)
      config.create_role_setting!(channel_id: 111)
      get server_path(guild.id)
    end

    context "without the server being authorized this session" do
      it "redirects to the picker" do
        new_config = create(:server_configuration, discord_id: 900_000_002, bot_role_position: 100)
        new_config.create_role_setting!
        set = create(:role_set, role_setting: new_config.role_setting)
        post server_role_set_repost_path(900_000_002, set.id), **turbo
        expect(response).to redirect_to(servers_path)
      end
    end

    describe "POST /servers/:server_id/role_sets/:role_set_id/repost" do
      context "when the roles plugin is enabled" do
        let!(:activation) { create(:plugin_activation, server_configuration: config, plugin: roles_plugin, enabled: true) }
        let!(:set) { create(:role_set, role_setting: config.role_setting) }

        it "publishes a repost event and returns ok with a toast stream" do
          post server_role_set_repost_path(guild.id, set.id), **turbo
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Reposting")
          expect(Bot::ConfigBus).to have_received(:repost_roles).with(set)
        end
      end

      context "when the roles plugin is disabled" do
        let!(:set) { create(:role_set, role_setting: config.role_setting) }

        it "returns 422 and does not publish" do
          post server_role_set_repost_path(guild.id, set.id), **turbo
          expect(response).to have_http_status(:unprocessable_content)
          expect(Bot::ConfigBus).not_to have_received(:repost_roles)
        end

        it "includes an error toast" do
          post server_role_set_repost_path(guild.id, set.id), **turbo
          expect(response.body).to include("Enable the Roles")
        end
      end

      context "when the role set belongs to a different server" do
        let!(:other_config) { create(:server_configuration, discord_id: 900_000_999, bot_role_position: 100) }
        let!(:other_setting) { create(:role_setting, server_configuration: other_config) }
        let!(:other_set) { create(:role_set, role_setting: other_setting) }

        it "returns 404 and does not publish" do
          post server_role_set_repost_path(guild.id, other_set.id), **turbo
          expect(response).to have_http_status(:not_found)
          expect(Bot::ConfigBus).not_to have_received(:repost_roles)
        end
      end

      context "without Turbo" do
        let!(:activation) { create(:plugin_activation, server_configuration: config, plugin: roles_plugin, enabled: true) }
        let!(:set) { create(:role_set, role_setting: config.role_setting) }

        it "redirects to the roles page" do
          post server_role_set_repost_path(guild.id, set.id)
          expect(response).to redirect_to(server_roles_path(guild.id))
        end
      end
    end
  end
end
