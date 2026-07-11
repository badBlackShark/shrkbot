# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Image scanning config", type: :request do
  include_context "discord auth"

  let(:guild) { Discord::Guild.new(id: 900_000_001, name: "Dev Refuge", owner: true, permissions: 0, icon: nil, member_count: 5) }
  let(:config) { ServerConfiguration.find_by(discord_id: guild.id) }
  let(:turbo) { {headers: {"Accept" => "text/vnd.turbo-stream.html"}} }

  context "when signed out" do
    it "redirects to the sign-in page" do
      get server_image_scanning_path(900_000_001)
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in" do
    let!(:moderation_plugin) { create(:plugin, key: "moderation", name: "Server Shield") }
    let!(:image_plugin) { create(:plugin, key: "image_scanning", name: "Scam Image Detection") }

    before do
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id)
      config.create_moderation_settings!
      config.create_spam_protection_settings!
      config.create_image_scanning_settings!
      allow(Discord::UserGuilds).to receive(:call).and_return([guild])
    end

    context "without proving the server is manageable this session" do
      it "redirects to the picker" do
        get server_image_scanning_path(guild.id)
        expect(response).to redirect_to(servers_path)
      end
    end

    context "after loading the dashboard authorizes the server" do
      before { get server_path(guild.id) }

      describe "GET /servers/:server_id/image_scanning" do
        context "when group is enabled and staff role is present" do
          before do
            create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: false)
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

        context "when group is disabled" do
          it "returns 200 and renders the prereq gate" do
            get server_image_scanning_path(guild.id)
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("Server Shield group is disabled")
            expect(response.body).to include("Open Server Shield overview")
          end
        end

        context "when group is enabled but no staff role set" do
          before do
            create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: false)
              .update_column(:enabled, true)
          end

          it "returns 200 with locked toggle and warning callout" do
            get server_image_scanning_path(guild.id)
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("Pick a staff role first.")
            expect(response.body).not_to include("Server Shield group is disabled")
          end
        end
      end

      describe "PATCH /servers/:server_id/image_scanning" do
        before do
          create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: false)
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

        context "when toggled from the overview" do
          subject(:patch_from_overview) do
            patch server_image_scanning_path(guild.id),
              params: {image_scanning: {sensitivity: "standard", action: "delete",
                                        punishment: "none", timeout_seconds: 3600,
                                        confirmed_punishment: "none", confirmed_timeout_seconds: 3600,
                                        custom_keyword_min_hits: 2,
                                        custom_keywords: [], enabled: "0"},
                       from_overview: "1"}
          end

          it "redirects to the moderation overview" do
            patch_from_overview
            expect(response).to redirect_to(server_moderation_path(guild.id))
          end
        end
      end
    end
  end
end
