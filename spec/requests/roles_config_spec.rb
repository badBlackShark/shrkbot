# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Roles config", type: :request do
  let(:auth) do
    OmniAuth::AuthHash.new(
      provider: "discord",
      uid: "12345",
      info: {name: "shrk"},
      credentials: {token: "discord-access-token"}
    )
  end

  let(:guild) { Discord::Guild.new(id: 900_000_001, name: "Dev Refuge", owner: true, permissions: 0, icon: nil, member_count: 5) }
  let(:config) { ServerConfiguration.find_by(discord_id: guild.id) }
  let(:turbo) { {headers: {"Accept" => "text/vnd.turbo-stream.html"}} }

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:discord] = auth
    Rails.application.env_config["omniauth.auth"] = auth
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:discord] = nil
    Rails.application.env_config.delete("omniauth.auth")
  end

  context "when signed out" do
    it "redirects to the sign-in page" do
      get server_roles_path(900_000_001)
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in" do
    let!(:roles) { create(:plugin, key: "roles", name: "Roles") }

    before do
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id)
      config.create_role_setting!
      create(:server_channel, server_configuration: config, name: "get-roles", discord_id: 111)
      create(:server_role, server_configuration: config, discord_id: 222, name: "Member", position: 1)
      allow(Discord::UserGuilds).to receive(:call).and_return([guild])
    end

    context "without proving the server is manageable this session" do
      it "redirects to the picker" do
        get server_roles_path(guild.id)
        expect(response).to redirect_to(servers_path)
      end
    end

    context "after loading the dashboard authorizes the server" do
      before { get server_path(guild.id) }

      describe "GET /servers/:server_id/roles" do
        it "renders the config page in the app shell" do
          get server_roles_path(guild.id)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Roles")
          expect(response.body).to include("Role sets")
          expect(response.body).to include("Add role set")
        end

        it "marks roles active in the plugin sidebar" do
          get server_roles_path(guild.id)
          expect(response.body).to include("<aside").and include('aria-current="page"')
          expect(response.body).to include(server_logging_path(guild.id))
        end

        it "renders existing role sets with their roles selected" do
          set = create(:role_set, role_setting: config.role_setting, name: "Pings", selection_mode: "multi")
          create(:assignable_role, role_set: set, role_id: 222)
          get server_roles_path(guild.id)
          expect(response.body).to include("Pings")
        end

        it "tells the user when no channels have synced" do
          config.server_channels.destroy_all
          get server_roles_path(guild.id)
          expect(response.body).to include("No channels have synced")
        end

        it "warns about roles shrkbot can't assign" do
          get server_roles_path(guild.id)
          expect(response.body).to include("Greyed-out roles")
        end

        it "omits the warning when every role is assignable" do
          config.update!(bot_role_position: 100)
          get server_roles_path(guild.id)
          expect(response.body).not_to include("Greyed-out roles")
        end
      end

      describe "PATCH /servers/:server_id/roles" do
        it "creates a role set and enables the plugin in one request" do
          patch server_roles_path(guild.id),
            params: {
              roles: {
                channel_id: 111,
                enabled: "1",
                role_sets: {"0" => {name: "Pings", selection_mode: "multi", role_ids: ["222"]}}
              }
            },
            **turbo
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(config.role_setting.reload.channel_id).to eq(111)
          expect(config.role_setting.role_sets.last.assignable_roles.map(&:role_id)).to contain_exactly(222)
          expect(config.plugins.enabled.exists?(key: :roles)).to be(true)
          expect(response.body).to include("saved")
        end

        it "returns 422 without a body replace when enabling without a channel" do
          patch server_roles_path(guild.id),
            params: {roles: {channel_id: "", enabled: "1", role_sets: {}}},
            **turbo
          expect(response).to have_http_status(:unprocessable_content)
          expect(config.plugins.enabled.exists?(key: :roles)).to be(false)
          expect(response.body).not_to include('id="roles-config"')
        end

        it "falls back to a redirect without Turbo" do
          patch server_roles_path(guild.id),
            params: {roles: {channel_id: 111, enabled: "0", role_sets: {}}}
          expect(response).to redirect_to(server_roles_path(guild.id))
        end

        it "redirects with an alert when a non-Turbo save fails" do
          patch server_roles_path(guild.id),
            params: {roles: {channel_id: "", enabled: "1", role_sets: {}}}
          expect(response).to redirect_to(server_roles_path(guild.id))
          expect(flash[:alert]).to be_present
        end
      end
    end
  end
end
