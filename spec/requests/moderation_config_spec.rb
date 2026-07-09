# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Moderation config", type: :request do
  include_context "discord auth"

  let(:guild) { Discord::Guild.new(id: 900_000_001, name: "Dev Refuge", owner: true, permissions: 0, icon: nil, member_count: 5) }
  let(:config) { ServerConfiguration.find_by(discord_id: guild.id) }
  let(:turbo) { {headers: {"Accept" => "text/vnd.turbo-stream.html"}} }

  context "when signed out" do
    it "redirects to the sign-in page" do
      get server_moderation_path(900_000_001)
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in" do
    let!(:logging_plugin) { create(:plugin, key: "logging", name: "Logging") }
    let!(:moderation_plugin) { create(:plugin, key: "moderation", name: "Server Shield") }
    let!(:spam_plugin) { create(:plugin, key: "spam_protection", name: "Cross-Channel Spam Guard") }

    before do
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id)
      config.create_moderation_settings!
      config.create_logging_setting!
      config.create_spam_protection_settings!
      config.create_image_scanning_settings!
      allow(Discord::UserGuilds).to receive(:call).and_return([guild])
    end

    context "without proving the server is manageable this session" do
      it "redirects to the picker" do
        get server_moderation_path(guild.id)
        expect(response).to redirect_to(servers_path)
      end
    end

    context "after loading the dashboard authorizes the server" do
      before do
        get server_path(guild.id)
      end

      describe "GET /servers/:server_id/moderation" do
        context "when logging is ready and group is enabled" do
          before do
            config.logging_setting.update!(channel_id: 111)
            create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false)
              .update_column(:enabled, true)
            create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: false)
              .update_column(:enabled, true)
          end

          it "renders the overview page with the Server Shield title" do
            get server_moderation_path(guild.id)
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("Server Shield")
          end

          it "renders the sub-plugin directory" do
            get server_moderation_path(guild.id)
            expect(response.body).to include("Sub-plugins")
            expect(response.body).to include("Cross-Channel Spam Guard")
            expect(response.body).to include("Scam Image Detection")
          end

          it "renders the matching explainer" do
            get server_moderation_path(guild.id)
            expect(response.body).to include("How text matching works")
          end

          it "renders the save bar wired to the form" do
            get server_moderation_path(guild.id)
            expect(response.body).to include("save-bar").and include("Unsaved changes")
          end

          context "when the logging channel has a server_channel record with a name" do
            before do
              create(:server_channel, server_configuration: config, discord_id: 111, name: "mod-log")
            end

            it "renders the logging subline with the channel name" do
              get server_moderation_path(guild.id)
              expect(response.body).to include("#mod-log")
            end
          end
        end

        context "when group is disabled but logging is ready" do
          before do
            config.logging_setting.update!(channel_id: 111)
            create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false)
              .update_column(:enabled, true)
          end

          it "renders the page with the enable gate" do
            get server_moderation_path(guild.id)
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("Server Shield")
          end
        end

        context "when logging is not ready" do
          it "renders the page with the prereq gate" do
            get server_moderation_path(guild.id)
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("Moderation needs the Logging plugin")
            expect(response.body).to include("Set up Logging")
          end
        end
      end

      describe "PATCH /servers/:server_id/moderation" do
        before do
          config.logging_setting.update!(channel_id: 111)
          create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false)
            .update_column(:enabled, true)
          create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: false)
            .update_column(:enabled, true)
          create(:server_role, server_configuration: config, discord_id: 500, name: "Moderator")
        end

        it "saves the staff role and returns turbo stream on success" do
          patch server_moderation_path(guild.id),
            params: {moderation: {staff_role_id: 500, enabled: "1"}},
            **turbo
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(config.moderation_settings.reload.staff_role_id).to eq(500)
          expect(response.body).to include("moderation-config")
          expect(response.body).to include("saved")
        end

        it "returns 422 when clearing the staff role while a sub-plugin is enabled" do
          create(:plugin_activation, server_configuration: config, plugin: spam_plugin, enabled: false)
            .update_column(:enabled, true)
          config.moderation_settings.update!(staff_role_id: 500)

          patch server_moderation_path(guild.id),
            params: {moderation: {staff_role_id: "", enabled: "1"}},
            **turbo
          expect(response).to have_http_status(:unprocessable_content)
          expect(config.moderation_settings.reload.staff_role_id).to eq(500)
          expect(response.body).to include("A staff role is required while a sub-plugin is enabled.")
        end

        it "falls back to a redirect without Turbo" do
          patch server_moderation_path(guild.id),
            params: {moderation: {staff_role_id: 500, enabled: "1"}}
          expect(response).to redirect_to(server_moderation_path(guild.id))
        end
      end
    end
  end
end
