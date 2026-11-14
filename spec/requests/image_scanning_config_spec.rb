# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Image scanning config", type: :request do
  include_context "plugin config request"

  let(:plugin_path) { server_image_scanning_path(guild.id) }

  it_behaves_like "a config page that requires sign-in"

  context "when signed in" do
    let!(:logging_plugin) { create(:plugin, key: "logging", name: "Logging") }
    let!(:image_plugin) { create(:plugin, key: "image_scanning", name: "Scam Image Detection") }

    before do
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id)
      config.create_moderation_settings!
      config.create_logging_settings!
      config.create_spam_protection_settings!
      config.create_image_scanning_settings!
      allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    end

    it_behaves_like "a config page that requires a manageable server"

    context "after loading the dashboard authorizes the server" do
      before { get server_path(guild.id) }

      describe "GET /servers/:server_id/image_scanning" do
        context "when Logging is ready and a staff role is present" do
          before do
            config.logging_settings.update!(channel_id: 111)
            create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false)
              .update_column(:enabled, true)
            config.moderation_settings.update!(staff_role_id: 500)
            create(:server_role, server_configuration: config, discord_id: 500, name: "Moderator")
          end

          it "returns 200 and renders the page" do
            get server_image_scanning_path(guild.id)
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("Scam Image Detection")
          end

          it "renders the sensitivity options and consent callout" do
            get server_image_scanning_path(guild.id)
            expect(response.body).to include("Before you turn this on")
            expect(response.body).to include("Relaxed")
            expect(response.body).to include("Standard")
            expect(response.body).to include("Strict")
          end

          it "renders the report-as-scam hint" do
            get server_image_scanning_path(guild.id)
            expect(response.body).to include("Report as scam")
          end
        end

        context "when Logging and the staff role are missing" do
          it "lists both steps with a link each, and locks the toggle" do
            get server_image_scanning_path(guild.id)
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("Before you enable")
            expect(response.body).to include("Turn Logging on and pick a log channel. Every alert lands there.")
            expect(response.body).to include("Pick a staff role on the Server Shield overview.")
            expect(response.body).to include("Complete setup before enabling this plugin.")
          end
        end

        context "when only the staff role is missing" do
          before do
            config.logging_settings.update!(channel_id: 111)
            create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false)
              .update_column(:enabled, true)
          end

          it "lists the staff role step only" do
            get server_image_scanning_path(guild.id)
            expect(response.body).to include("Pick a staff role on the Server Shield overview.")
            expect(response.body).not_to include("Turn Logging on and pick a log channel.")
          end
        end
      end

      describe "PATCH /servers/:server_id/image_scanning" do
        before do
          config.logging_settings.update!(channel_id: 111)
          create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false)
            .update_column(:enabled, true)
          config.moderation_settings.update!(staff_role_id: 500)
        end

        it "saves settings and returns turbo stream on success" do
          patch server_image_scanning_path(guild.id),
            params: {image_scanning: {sensitivity: "standard", action: "delete",
                                      punishment: "none", timeout_seconds: 3600,
                                      confirmed_punishment: "none", confirmed_timeout_seconds: 3600,
                                      custom_keyword_min_hits: 2,
                                      custom_keywords: [], enabled: "0"}},
            **turbo
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(response.body).to include('target="plugin-sidebar"')
          expect(response.body).to include("image_scanning-config")
          expect(response.body).to include("saved")
        end

        it "returns 422 when enabling with no staff role" do
          config.moderation_settings.update!(staff_role_id: nil)
          create(:plugin_activation, server_configuration: config, plugin: image_plugin, enabled: false)

          patch server_image_scanning_path(guild.id),
            params: {image_scanning: {sensitivity: "standard", action: "delete",
                                      punishment: "none", timeout_seconds: 3600,
                                      confirmed_punishment: "none", confirmed_timeout_seconds: 3600,
                                      custom_keyword_min_hits: 2,
                                      custom_keywords: [], enabled: "1"}},
            **turbo
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("Scam Image Detection needs Logging enabled, and a staff role set on the Server Shield overview.")
        end

        it "falls back to a redirect without Turbo" do
          patch server_image_scanning_path(guild.id),
            params: {image_scanning: {sensitivity: "standard", action: "delete",
                                      punishment: "none", timeout_seconds: 3600,
                                      confirmed_punishment: "none", confirmed_timeout_seconds: 3600,
                                      custom_keyword_min_hits: 2,
                                      custom_keywords: [], enabled: "0"}}
          expect(response).to redirect_to(server_image_scanning_path(guild.id))
        end
      end
    end
  end
end
