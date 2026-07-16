# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Server dashboard", type: :request do
  include_context "discord auth"

  let(:guild) { Bot::Discord::Guild.new(id: 900_000_001, name: "Dev Refuge", owner: true, permissions: 0, icon: "icyhash", member_count: 2481) }
  let(:config) { ServerConfiguration.find_by(discord_id: guild.id) }

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
      allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    end

    describe "GET /servers/:id" do
      subject(:get_dashboard) { get server_path(guild.id) }

      it "frames the dashboard in the app shell with the server switcher" do
        get_dashboard
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Dev Refuge")
        expect(response.body).to include("2,481 members")
        expect(response.body).to include("0 channels and 0 roles synced")
        expect(response.body).to include("Add another server")
      end

      it "lists the three configurable plugins" do
        get_dashboard
        expect(response.body).to include("Roles").and include("Welcomes").and include("Logging")
      end

      it "lists moderation but not its sub-plugins on the dashboard" do
        create(:plugin, key: "moderation", name: "Server Shield")
        create(:plugin, key: "spam_protection", name: "Cross-Channel Spam Guard")
        create(:plugin, key: "image_scanning", name: "Scam Image Detection")
        get_dashboard
        expect(response.body).to include("plugin-moderation")
        expect(response.body).not_to include("plugin-spam_protection")
        expect(response.body).not_to include("plugin-image_scanning")
      end

      context "with another configured server" do
        let(:other_guild) { Bot::Discord::Guild.new(id: 900_000_002, name: "Speedrun HQ", owner: true, permissions: 0, icon: nil, member_count: 80) }

        before do
          create(:server_configuration, discord_id: other_guild.id)
          allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild, other_guild])
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

          welcomes

          config.create_logging_setting!(channel_id: 9)
          logging
        end

        it "shows enabled, needs-setup and disabled badges" do
          get_dashboard
          expect(response.body).to include("Enabled")
          expect(response.body).to include("Needs setup")
          expect(response.body).to include(">Disabled<")
        end

        it "disables the toggle for a plugin that isn't set up yet, explaining why" do
          get_dashboard
          expect(response.body).to include("Complete setup before enabling this plugin")
        end
      end

      it "shows reminders as an always-on plugin row" do
        get_dashboard
        expect(response.body).to include("Reminders")
        expect(response.body).to include("Global")
        expect(response.body).to include("always enabled to preserve DM functionality")
        expect(response.body).to include("disabled")
      end

      context "when Discord omits the member count" do
        let(:guild) { Bot::Discord::Guild.new(id: 900_000_001, name: "Dev Refuge", owner: true, permissions: 0, icon: nil) }

        it "renders the header without a member count" do
          get_dashboard
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Dev Refuge")
        end
      end

      context "when the server is not manageable by the user" do
        before do
          allow(Bot::Discord::UserGuilds).to receive(:call).and_return([])
        end

        it "redirects back to the picker" do
          get_dashboard
          expect(response).to redirect_to(servers_path)
        end
      end

      context "when the Discord token has expired" do
        before do
          allow(Bot::Discord::UserGuilds).to receive(:call).and_raise(Bot::Discord::UserGuilds::Unauthorized)
        end

        it "kicks off re-authentication" do
          get_dashboard
          expect(response.body).to include("Signing you back in")
          expect(session[:reauth_attempted]).to be(true)
        end
      end

      context "when Discord cannot be reached" do
        before do
          get server_path(guild.id)
          allow(Bot::Discord::UserGuilds).to receive(:call).and_raise(Bot::Discord::UserGuilds::Error)
        end

        context "when cached metadata is present" do
          before do
            config.update!(name: "Dev Refuge", icon_hash: "icyhash", member_count: 2481)
          end

          it "serves a 200 from the cache" do
            get_dashboard
            expect(response).to have_http_status(:ok)
          end

          it "renders the server name from the cache" do
            get_dashboard
            expect(response.body).to include("Dev Refuge")
          end
        end

        context "when no cached metadata is available" do
          it "renders the error state" do
            get_dashboard
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("reach Discord")
          end
        end
      end

      context "when the Discord token has expired and Discord is also unreachable" do
        before do
          get server_path(guild.id)
          allow(Bot::Discord::UserGuilds).to receive(:call).and_raise(Bot::Discord::UserGuilds::Unauthorized)
          config.update!(name: "Dev Refuge", icon_hash: "icyhash", member_count: 2481)
        end

        it "still kicks off re-authentication without falling back to cache" do
          get_dashboard
          expect(response.body).to include("Signing you back in")
        end
      end
    end

    describe "PATCH /servers/:server_id/plugins/:id" do
      let(:turbo) { {headers: {"Accept" => "text/vnd.turbo-stream.html"}} }

      before do
        get server_path(guild.id)
      end

      it "enables a plugin in place, re-verifying live authorization first" do
        config.create_role_setting!(channel_id: 7)
        roles
        patch server_plugin_path(guild.id, "roles"), params: {enabled: true}, **turbo
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(config.plugin_activations.find_by(plugin: roles).enabled).to be(true)
        expect(Bot::Discord::UserGuilds).to have_received(:call).twice
      end

      it "refuses to enable a plugin missing its prerequisites" do
        logging
        patch server_plugin_path(guild.id, "logging"), params: {enabled: true}, **turbo
        expect(response.body).to match(/required settings/)
        expect(config.plugin_activations).to be_empty
      end

      it "disables an enabled plugin" do
        config.create_role_setting!(channel_id: 7)
        create(:plugin_activation, server_configuration: config, plugin: roles, enabled: true)
        patch server_plugin_path(guild.id, "roles"), params: {enabled: false}, **turbo
        expect(config.plugin_activations.find_by(plugin: roles).enabled).to be(false)
      end

      it "redirects an unknown plugin key back to the dashboard" do
        patch server_plugin_path(guild.id, "nope"), params: {enabled: true}, **turbo
        expect(response).to redirect_to(server_path(guild.id))
        expect(flash[:alert]).to be_present
      end

      it "falls back to a redirect without Turbo" do
        config.create_role_setting!(channel_id: 7)
        roles
        patch server_plugin_path(guild.id, "roles"), params: {enabled: true}
        expect(response).to redirect_to(server_path(guild.id))
      end
    end

    describe "toggling a server the user no longer manages" do
      before do
        allow(Bot::Discord::UserGuilds).to receive(:call).and_return([])
      end

      it "redirects to the picker" do
        roles
        patch server_plugin_path(guild.id, "roles"), params: {enabled: true}
        expect(response).to redirect_to(servers_path)
      end
    end
  end
end
