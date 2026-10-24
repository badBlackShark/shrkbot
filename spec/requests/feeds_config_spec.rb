# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Feeds config", type: :request do
  include_context "plugin config request"

  let(:plugin_path) { server_feeds_path(guild.id) }

  it_behaves_like "a config page that requires sign-in"

  context "when signed in" do
    let!(:feeds_plugin) { create(:plugin, key: "feeds", name: "Feeds") }
    let!(:steam_news_plugin) { create(:plugin, key: "steam_news", name: "Steam News") }

    before do
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id)
      allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    end

    it_behaves_like "a config page that requires a manageable server"

    context "after loading the dashboard authorizes the server" do
      before { get server_path(guild.id) }

      describe "GET /servers/:server_id/feeds" do
        before { create(:plugin_activation, server_configuration: config, plugin: feeds_plugin, enabled: true) }

        it "lists the Steam News sub-plugin with a link to its page" do
          get plugin_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Steam News")
          expect(response.body).to include(server_steam_news_path(guild.id))
        end

        context "when Feeds is off" do
          before { config.plugin_activations.update_all(enabled: false) }

          it "renders the enable gate" do
            get plugin_path

            expect(response.body).to include("Enable Feeds to post news from the sources you follow.")
          end
        end
      end

      describe "PATCH /servers/:server_id/feeds" do
        subject(:toggle) { patch plugin_path, params: {feeds: {enabled:}}, **headers }

        let(:enabled) { "1" }
        let(:headers) { turbo }

        it "enables Feeds and re-renders the overview" do
          toggle

          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(response.body).to include("feeds-config")
          expect(config.enabled_plugin_keys).to include(:feeds)
        end

        context "when disabling" do
          let(:enabled) { "0" }

          before { create(:plugin_activation, server_configuration: config, plugin: feeds_plugin, enabled: true) }

          it "disables Feeds" do
            toggle

            expect(response).to have_http_status(:ok)
            expect(config.enabled_plugin_keys).not_to include(:feeds)
          end
        end

        context "without a Turbo Stream" do
          let(:headers) { {} }

          it "redirects back with the saved notice" do
            toggle

            expect(response).to redirect_to(plugin_path)
            expect(flash[:notice]).to eq("Feeds settings saved.")
          end
        end
      end
    end
  end
end
