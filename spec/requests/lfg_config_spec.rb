# frozen_string_literal: true

require "rails_helper"

RSpec.describe "LFG config", type: :request do
  include_context "discord auth"

  let(:guild) { Bot::Discord::Guild.new(id: 900_000_001, name: "Dev Refuge", owner: true, permissions: 0, icon: nil, member_count: 5) }
  let(:config) { ServerConfiguration.find_by(discord_id: guild.id) }
  let(:turbo) { {headers: {"Accept" => "text/vnd.turbo-stream.html"}} }

  context "when signed out" do
    it "redirects to the sign-in page" do
      get server_lfg_path(900_000_001)
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in" do
    let!(:lfg_plugin) { create(:plugin, key: "lfg", name: "Looking for Game") }

    before do
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id)
      config.create_lfg_settings!
      create(:server_role, server_configuration: config, discord_id: 222, name: "Member", position: 1)
      create(:server_role, server_configuration: config, discord_id: 333, name: "VIP", position: 2)
      create(:server_channel, server_configuration: config, discord_id: 111, name: "lfg")
      allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    end

    context "when the user no longer manages the server" do
      before do
        allow(Bot::Discord::UserGuilds).to receive(:call).and_return([])
      end

      it "redirects to the picker" do
        get server_lfg_path(guild.id)
        expect(response).to redirect_to(servers_path)
      end
    end

    context "after loading the dashboard authorizes the server" do
      before do
        get server_path(guild.id)
      end

      describe "GET /servers/:server_id/lfg" do
        it "renders the config page in the app shell" do
          get server_lfg_path(guild.id)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Looking for Game")
          expect(response.body).to include("Pingable roles")
          expect(response.body).to include("Add role")
          expect(response.body).to include("Make your LFG roles non-mentionable")
          expect(response.body).to include("Restrict who can run /lfg")
        end

        it "marks lfg active in the plugin sidebar" do
          get server_lfg_path(guild.id)
          expect(response.body).to include("<aside").and include('aria-current="page"')
          expect(response.body).to include(server_logging_path(guild.id))
        end

        context "with an existing pingable role" do
          before do
            create(:lfg_pingable_role, lfg_settings: config.lfg_settings, role_id: 222)
          end

          it "renders the role's name" do
            get server_lfg_path(guild.id)
            expect(response.body).to include("Member")
          end
        end
      end

      describe "PATCH /servers/:server_id/lfg" do
        it "saves the settings and returns a turbo stream on success" do
          patch server_lfg_path(guild.id),
            params: {
              lfg: {
                enabled: "1",
                cooldown_seconds: 120,
                post_lifetime_minutes: 240,
                default_min_membership_days: 3
              }
            },
            **turbo
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(config.lfg_settings.reload.cooldown_seconds).to eq(120)
          expect(config.lfg_settings.post_lifetime_minutes).to eq(240)
          expect(config.lfg_settings.default_min_membership_days).to eq(3)
          expect(config.plugins.enabled.exists?(key: :lfg)).to be(true)
          expect(response.body).to include("lfg-config")
          expect(response.body).to include("saved")
        end

        it "creates a pingable role from nested params" do
          patch server_lfg_path(guild.id),
            params: {
              lfg: {
                enabled: "1",
                cooldown_seconds: 300,
                post_lifetime_minutes: 360,
                pingable_roles: {"0" => {role_id: 222, required_role_ids: ["333"]}}
              }
            },
            **turbo
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          role = config.lfg_settings.reload.pingable_roles.find_by(role_id: 222)
          expect(role).to be_present
          expect(role.required_role_ids).to eq([333])
        end

        context "with an existing pingable role" do
          before do
            create(:lfg_pingable_role, lfg_settings: config.lfg_settings, role_id: 222)
          end

          it "deletes it by omission" do
            patch server_lfg_path(guild.id),
              params: {
                lfg: {
                  enabled: "1",
                  cooldown_seconds: 300,
                  post_lifetime_minutes: 360
                }
              },
              **turbo
            expect(config.lfg_settings.reload.pingable_roles).to be_empty
          end
        end

        it "rejects a pingable role's role_id from another server with 404" do
          patch server_lfg_path(guild.id),
            params: {
              lfg: {
                enabled: "1",
                cooldown_seconds: 300,
                post_lifetime_minutes: 360,
                pingable_roles: {"0" => {role_id: 424_242}}
              }
            },
            **turbo
          expect(response).to have_http_status(:not_found)
        end

        it "rejects a default required role from another server with 404" do
          patch server_lfg_path(guild.id),
            params: {
              lfg: {
                enabled: "1",
                cooldown_seconds: 300,
                post_lifetime_minutes: 360,
                default_required_role_ids: ["424242"]
              }
            },
            **turbo
          expect(response).to have_http_status(:not_found)
        end

        it "rejects a foreign channel id with 404" do
          patch server_lfg_path(guild.id),
            params: {
              lfg: {
                enabled: "1",
                cooldown_seconds: 300,
                post_lifetime_minutes: 360,
                allowed_channel_ids: ["424242"]
              }
            },
            **turbo
          expect(response).to have_http_status(:not_found)
        end

        it "falls back to a redirect without Turbo" do
          patch server_lfg_path(guild.id),
            params: {lfg: {enabled: "0", cooldown_seconds: 300, post_lifetime_minutes: 360}}
          expect(response).to redirect_to(server_lfg_path(guild.id))
        end
      end
    end
  end
end
