# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Logging config", type: :request do
  include_context "discord auth"

  let(:guild) { Bot::Discord::Guild.new(id: 900_000_001, name: "Dev Refuge", owner: true, permissions: 0, icon: nil, member_count: 5) }
  let(:config) { ServerConfiguration.find_by(discord_id: guild.id) }
  let(:turbo) { {headers: {"Accept" => "text/vnd.turbo-stream.html"}} }

  context "when signed out" do
    it "redirects to the sign-in page" do
      get server_logging_path(900_000_001)
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in" do
    let!(:logging) { create(:plugin, key: "logging", name: "Logging") }

    before do
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id)
      config.create_logging_setting!
      allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    end

    context "when the user no longer manages the server" do
      before do
        allow(Bot::Discord::UserGuilds).to receive(:call).and_return([])
      end

      it "redirects to the picker" do
        get server_logging_path(guild.id)
        expect(response).to redirect_to(servers_path)
      end
    end

    context "after loading the dashboard authorizes the server" do
      before do
        get server_path(guild.id)
      end

      context "when the user is demoted afterward" do
        before do
          allow(Bot::Discord::UserGuilds).to receive(:call).and_return([])
        end

        it "redirects a page load to the picker" do
          get server_logging_path(guild.id)
          expect(response).to redirect_to(servers_path)
        end

        it "redirects a save attempt to the picker" do
          patch server_logging_path(guild.id), params: {logging: {channel_id: 200, enabled: "1", actions: {}}}
          expect(response).to redirect_to(servers_path)
        end
      end

      context "when Discord is unreachable after the dashboard cached authorization" do
        before do
          allow(Bot::Discord::UserGuilds).to receive(:call).and_raise(Bot::Discord::UserGuilds::Error)
        end

        it "still serves the config page from the cached authorization" do
          get server_logging_path(guild.id)
          expect(response).to have_http_status(:ok)
        end
      end

      describe "GET /servers/:server_id/logging" do
        it "renders the config page with the event matrix" do
          get server_logging_path(guild.id)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Logging")
          expect(response.body).to include("Logged events")
          expect(response.body).to include("Member gained a role")
          expect(response.body).to include("Member lost a role")
        end

        context "when the plugin is already enabled" do
          before do
            config.logging_setting.update!(channel_id: 200)
            create(:plugin_activation, server_configuration: config, plugin: logging, enabled: true)
            get server_path(guild.id)
          end

          it "renders the matrix without the disabled overlay gating it" do
            get server_logging_path(guild.id)
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("Member gained a role")
          end
        end
      end

      describe "PATCH /servers/:server_id/logging" do
        before do
          create(:server_channel, server_configuration: config, name: "mod-log", discord_id: 200)
        end

        it "saves the channel, event toggles, and enables the plugin" do
          patch server_logging_path(guild.id),
            params: {logging: {channel_id: 200, enabled: "1", actions: {"roles.role_gained" => "1", "roles.role_lost" => "0"}}},
            **turbo
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(config.logging_setting.reload.channel_id).to eq(200)
          expect(config.logging_setting.action_enabled?("roles.role_gained")).to be(true)
          expect(config.plugins.enabled.exists?(key: :logging)).to be(true)
          expect(response.body).to include("saved")
          expect(response.body).to include('target="plugin-sidebar"')
        end

        it "exposes which channels are public so it can warn before saving" do
          patch server_logging_path(guild.id),
            params: {logging: {channel_id: 200, enabled: "1", actions: {}}},
            **turbo
          expect(response.body).to include("public")
          expect(response.body).to include("channel-warning-visible-ids-value")
        end

        it "re-renders with an inline error when enabling without a channel" do
          patch server_logging_path(guild.id),
            params: {logging: {channel_id: "", enabled: "1", actions: {}}},
            **turbo
          expect(response).to have_http_status(:unprocessable_content)
          expect(config.plugins.enabled.exists?(key: :logging)).to be(false)
          expect(response.body).to include("logging-config")
          expect(response.body).to include("settings to be configured")
        end

        it "falls back to a redirect without Turbo" do
          patch server_logging_path(guild.id),
            params: {logging: {channel_id: 200, enabled: "1", actions: {}}}
          expect(response).to redirect_to(server_logging_path(guild.id))
        end

        it "redirects with an alert when a non-Turbo save fails" do
          patch server_logging_path(guild.id),
            params: {logging: {channel_id: "", enabled: "1", actions: {}}}
          expect(response).to redirect_to(server_logging_path(guild.id))
          expect(flash[:alert]).to be_present
        end
      end
    end
  end
end
