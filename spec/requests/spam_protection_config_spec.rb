# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Spam protection config", type: :request do
  include_context "discord auth"

  let(:guild) { Bot::Discord::Guild.new(id: 900_000_001, name: "Dev Refuge", owner: true, permissions: 0, icon: nil, member_count: 5) }
  let(:config) { ServerConfiguration.find_by(discord_id: guild.id) }
  let(:turbo) { {headers: {"Accept" => "text/vnd.turbo-stream.html"}} }

  context "when signed out" do
    it "redirects to the sign-in page" do
      get server_spam_protection_path(900_000_001)
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in" do
    let!(:moderation_plugin) { create(:plugin, key: "moderation", name: "Server Shield") }
    let!(:spam_plugin) { create(:plugin, key: "spam_protection", name: "Cross-Channel Spam Guard") }

    before do
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id)
      config.create_moderation_settings!
      config.create_spam_protection_settings!
      config.create_image_scanning_settings!
      allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    end

    context "when the user no longer manages the server" do
      before do
        allow(Bot::Discord::UserGuilds).to receive(:call).and_return([])
      end

      it "redirects to the picker" do
        get server_spam_protection_path(guild.id)
        expect(response).to redirect_to(servers_path)
      end
    end

    context "after loading the dashboard authorizes the server" do
      before { get server_path(guild.id) }

      describe "GET /servers/:server_id/spam_protection" do
        context "when group is enabled and staff role is present" do
          before do
            create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: false)
              .update_column(:enabled, true)
            config.moderation_settings.update!(staff_role_id: 500)
            create(:server_role, server_configuration: config, discord_id: 500, name: "Moderator")
          end

          it "returns 200 and renders the page" do
            get server_spam_protection_path(guild.id)
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("Cross-Channel Spam Guard")
          end

          it "renders the detection and response controls" do
            get server_spam_protection_path(guild.id)
            expect(response.body).to include("Trigger threshold")
            expect(response.body).to include("Match strictness")
            expect(response.body).to include("When spam is detected")
          end
        end

        context "when group is disabled" do
          it "returns 200 and renders the prereq gate" do
            get server_spam_protection_path(guild.id)
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

          it "returns 200 with no gate but locked toggle and warning callout" do
            get server_spam_protection_path(guild.id)
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("Pick a staff role first.")
            expect(response.body).not_to include("Server Shield group is disabled")
          end
        end
      end

      describe "PATCH /servers/:server_id/spam_protection" do
        before do
          create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: false)
            .update_column(:enabled, true)
          config.moderation_settings.update!(staff_role_id: 500)
        end

        it "saves settings and returns turbo stream on success" do
          patch server_spam_protection_path(guild.id),
            params: {spam_protection: {channel_threshold: 3, window_seconds: 10, similarity: 0.9,
                                       match_symbol_only_messages: "0", action: "purge", punishment: "none",
                                       timeout_seconds: 3600, enabled: "0"}},
            **turbo
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(response.body).to include('target="plugin-sidebar"')
          expect(response.body).to include("spam_protection-config")
          expect(response.body).to include("saved")
        end

        it "surfaces the validation message when a value exceeds its maximum" do
          patch server_spam_protection_path(guild.id),
            params: {spam_protection: {channel_threshold: 3, window_seconds: 99, similarity: 0.9,
                                       match_symbol_only_messages: "0", action: "purge", punishment: "none",
                                       timeout_seconds: 3600, enabled: "0"}},
            **turbo
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("must be less than or equal to 60")
        end

        it "persists nothing when a value is out of range" do
          patch server_spam_protection_path(guild.id),
            params: {spam_protection: {channel_threshold: 3, window_seconds: 99, similarity: 0.9,
                                       match_symbol_only_messages: "0", action: "purge", punishment: "none",
                                       timeout_seconds: 3600, enabled: "0"}},
            **turbo
          expect(config.spam_protection_settings.reload.window_seconds).not_to eq(99)
        end

        it "returns 422 when enabling with no staff role" do
          config.moderation_settings.update!(staff_role_id: nil)
          create(:plugin_activation, server_configuration: config, plugin: spam_plugin, enabled: false)

          patch server_spam_protection_path(guild.id),
            params: {spam_protection: {channel_threshold: 3, window_seconds: 10, similarity: 0.9,
                                       match_symbol_only_messages: "0", action: "purge", punishment: "none",
                                       timeout_seconds: 3600, enabled: "1"}},
            **turbo
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "falls back to a redirect without Turbo" do
          patch server_spam_protection_path(guild.id),
            params: {spam_protection: {channel_threshold: 3, window_seconds: 10, similarity: 0.9,
                                       match_symbol_only_messages: "0", action: "purge", punishment: "none",
                                       timeout_seconds: 3600, enabled: "0"}}
          expect(response).to redirect_to(server_spam_protection_path(guild.id))
        end

        context "when toggled from the overview" do
          subject(:patch_from_overview) do
            patch server_spam_protection_path(guild.id),
              params: {spam_protection: {channel_threshold: 3, window_seconds: 10, similarity: 0.9,
                                         match_symbol_only_messages: "0", action: "purge", punishment: "none",
                                         timeout_seconds: 3600, enabled: "0"},
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
