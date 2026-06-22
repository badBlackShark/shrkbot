require "rails_helper"

RSpec.describe "Server dashboard", type: :request do
  let(:auth) do
    OmniAuth::AuthHash.new(
      provider: "discord",
      uid: "12345",
      info: {name: "shrk"},
      credentials: {token: "discord-access-token"}
    )
  end

  let(:guild) { Discord::Guild.new(id: 900_000_001, name: "Dev Refuge", owner: true, permissions: 0, icon: "icyhash", member_count: 2481) }
  let(:config) { ServerConfiguration.find_by(discord_id: guild.id) }

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
      get server_path(900_000_001)
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in" do
    let(:logging) { create(:plugin, key: "logging", name: "Logging") }
    let(:roles) { create(:plugin, key: "roles", name: "Roles") }
    let(:welcomes) { create(:plugin, key: "welcomes", name: "Welcomes") }

    before do
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id)
      allow(Discord::UserGuilds).to receive(:call).and_return([guild])
    end

    describe "GET /servers/:id" do
      subject(:get_dashboard) { get server_path(guild.id) }

      it "frames the dashboard in the app shell with the server switcher" do
        get_dashboard
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Dev Refuge")
        expect(response.body).to include("2,481 members")
        expect(response.body).to include("Add another server")
      end

      it "lists the three configurable plugins" do
        get_dashboard
        expect(response.body).to include("Roles").and include("Welcomes").and include("Logging")
      end

      context "with another configured server" do
        let(:other_guild) { Discord::Guild.new(id: 900_000_002, name: "Speedrun HQ", owner: true, permissions: 0, icon: nil, member_count: 80) }

        before do
          create(:server_configuration, discord_id: other_guild.id)
          allow(Discord::UserGuilds).to receive(:call).and_return([guild, other_guild])
        end

        it "offers it in the switcher" do
          get_dashboard
          expect(response.body).to include("Speedrun HQ")
        end
      end

      context "with plugins in every state" do
        before do
          config.create_role_setting!(channel_id: 7)
          create(:plugin_activation, server_configuration: config, plugin: roles, enabled: true)

          config.create_welcome_settings!(channel_id: 5)
          create(:plugin_activation, server_configuration: config, plugin: welcomes, enabled: true)
          config.welcome_settings.destroy

          logging
        end

        it "shows enabled, needs-setup and off badges" do
          get_dashboard
          expect(response.body).to include("Enabled")
          expect(response.body).to include("Needs setup")
          expect(response.body).to include("Off")
        end
      end

      it "shows the force-DM setting and the /remind note" do
        get_dashboard
        expect(response.body).to include("Force reminder delivery via DM")
        expect(response.body).to include("/remind")
      end

      context "when Discord omits the member count" do
        let(:guild) { Discord::Guild.new(id: 900_000_001, name: "Dev Refuge", owner: true, permissions: 0, icon: nil) }

        it "renders the header without a member count" do
          get_dashboard
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Dev Refuge")
        end
      end

      context "when the server is not manageable by the user" do
        before { allow(Discord::UserGuilds).to receive(:call).and_return([]) }

        it "redirects back to the picker" do
          get_dashboard
          expect(response).to redirect_to(servers_path)
        end
      end

      context "when the Discord token has expired" do
        before { allow(Discord::UserGuilds).to receive(:call).and_raise(Discord::UserGuilds::Unauthorized) }

        it "bounces to the picker to re-authenticate" do
          get_dashboard
          expect(response).to redirect_to(servers_path)
        end
      end

      context "when Discord cannot be reached" do
        before { allow(Discord::UserGuilds).to receive(:call).and_raise(Discord::UserGuilds::Error) }

        it "redirects to the picker with an error" do
          get_dashboard
          expect(response).to redirect_to(servers_path)
          expect(flash[:alert]).to be_present
        end
      end
    end

    describe "PATCH /servers/:id/plugins/:key" do
      it "enables a plugin once its prerequisites are met" do
        config.create_role_setting!(channel_id: 7)
        roles
        patch toggle_plugin_server_path(guild.id, "roles"), params: {enabled: true}
        expect(response).to redirect_to(server_path(guild.id))
        expect(config.plugin_activations.find_by(plugin: roles).enabled).to be(true)
      end

      it "refuses to enable a plugin missing its prerequisites" do
        logging
        patch toggle_plugin_server_path(guild.id, "logging"), params: {enabled: true}
        expect(flash[:alert]).to match(/required settings/)
        expect(config.plugin_activations).to be_empty
      end

      it "disables an enabled plugin" do
        config.create_role_setting!(channel_id: 7)
        create(:plugin_activation, server_configuration: config, plugin: roles, enabled: true)
        patch toggle_plugin_server_path(guild.id, "roles"), params: {enabled: false}
        expect(config.plugin_activations.find_by(plugin: roles).enabled).to be(false)
      end

      it "rejects an unknown plugin key" do
        patch toggle_plugin_server_path(guild.id, "nope"), params: {enabled: true}
        expect(response).to redirect_to(server_path(guild.id))
        expect(flash[:alert]).to be_present
      end
    end

    describe "PATCH /servers/:id" do
      it "saves the force-DM setting" do
        patch server_path(guild.id), params: {force_dm_reminders: true}
        expect(response).to redirect_to(server_path(guild.id))
        expect(config.reload.force_dm_reminders).to be(true)
      end
    end
  end
end
