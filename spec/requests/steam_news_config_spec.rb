# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Steam News config", type: :request do
  include_context "plugin config request"

  let(:plugin_path) { server_steam_news_path(guild.id) }

  it_behaves_like "a config page that requires sign-in"

  context "when signed in" do
    let!(:feeds_plugin) { create(:plugin, key: "feeds", name: "Feeds") }
    let!(:steam_news_plugin) { create(:plugin, key: "steam_news", name: "Steam News") }
    let(:feeds_enabled) { true }

    before do
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id)
      create(:plugin_activation, server_configuration: config, plugin: feeds_plugin, enabled: true) if feeds_enabled
      allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    end

    it_behaves_like "a config page that requires a manageable server"

    context "after loading the dashboard authorizes the server" do
      before { get server_path(guild.id) }

      describe "GET /servers/:server_id/steam_news" do
        context "when Feeds is off" do
          let(:feeds_enabled) { false }

          it "renders the prerequisite gate and a locked toggle" do
            get plugin_path

            expect(response).to have_http_status(:ok)
            expect(response.body).to include("Feeds is off")
            expect(response.body).to include("Go to Feeds")
            expect(response.body).to include("Turn Feeds on first.")
          end
        end

        context "when Feeds is on and the server follows no games" do
          it "renders the empty state" do
            get plugin_path

            expect(response.body).to include("Part of")
            expect(response.body).to include("No games yet")
          end
        end

        context "when the server follows games" do
          let(:hades) { create(:integration_watch, name: "Hades II") }
          let(:tf2) { create(:integration_watch, name: "Team Fortress 2") }

          before do
            create(:server_channel, server_configuration: config, discord_id: 777, name: "news")
            create(:server_role, server_configuration: config, discord_id: 888, name: "Gamers")
            hades_subscription = create(:feed_subscription, server_configuration: config, watch: hades, channel_id: 777, role_id: 888)
            create(:feed_subscribed_event, subscription: hades_subscription, event_type: "Integrations::Steam::ArticlePublished")
            create(:feed_subscribed_event, subscription: hades_subscription, event_type: "Integrations::Steam::PatchNotesPublished")
            create(:feed_subscription, server_configuration: config, watch: tf2, channel_id: 999)
          end

          it "lists each game with its channel, role and event types" do
            get plugin_path

            expect(response.body).to include("Hades II", "#news", "pings @Gamers", "Patch notes", "Articles")
            expect(response.body).to include("Team Fortress 2", "no ping", "channel deleted")
          end

          it "offers adding, editing and stopping on a real server" do
            get plugin_path

            expect(response.body).to include("Add a game", new_server_steam_news_subscription_path(guild.id))
            expect(response.body).to include(edit_server_steam_news_subscription_path(guild.id, Feeds::Subscription.find_by!(watch: hades)))
            expect(response.body).to include("Stop following")
          end

          it "orders event types patch notes first" do
            get plugin_path

            expect(response.body.index("Patch notes")).to be < response.body.index("Articles")
          end

          it "lists games alphabetically" do
            get plugin_path

            expect(response.body.index("Hades II")).to be < response.body.index("Team Fortress 2")
          end

          it "shows no warning while the watch answers" do
            get plugin_path

            expect(response.body).not_to include("hasn't answered")
          end

          context "when a game's ping role was deleted from the server" do
            before { Feeds::Subscription.find_by!(watch: tf2).update!(role_id: 555) }

            it "says the role is gone instead of claiming no ping" do
              get plugin_path

              expect(response.body).to include("pings a role that was deleted")
              expect(response.body).not_to include("no ping")
            end
          end

          context "when a watch has been failing for over a day" do
            before { hades.update!(failing_since: 3.days.ago) }

            it "warns on that game's row" do
              get plugin_path

              expect(response.body).to include("Steam hasn&#39;t answered for this game since")
            end
          end
        end

        context "when the server is at the follow cap" do
          before { create_list(:feed_subscription, Feeds::Subscription::MAX_PER_SERVER, server_configuration: config) }

          it "disables Add and gives the reason" do
            get plugin_path

            expect(response.body).to match(/<button[^>]*disabled[^>]*aria-describedby="feed-subscriptions-cap"[^>]*>|<button[^>]*aria-describedby="feed-subscriptions-cap"[^>]*disabled[^>]*>/)
            expect(response.body).to include("This server follows 25 games, the most it can.")
          end
        end

        context "when another server follows a game" do
          before do
            other = create(:server_configuration)
            create(:feed_subscription, server_configuration: other, watch: create(:integration_watch, name: "Elsewhere"))
          end

          it "does not list it" do
            get plugin_path

            expect(response.body).not_to include("Elsewhere")
          end
        end
      end

      describe "PATCH /servers/:server_id/steam_news" do
        subject(:toggle) { patch plugin_path, params: {steam_news: {enabled: "1"}}.merge(extra_params), **headers }

        let(:extra_params) { {} }
        let(:headers) { turbo }

        it "enables Steam News when Feeds is on" do
          toggle

          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(response.body).to include("steam_news-config")
          expect(config.enabled_plugin_keys).to include(:steam_news)
        end

        context "when Feeds is off" do
          let(:feeds_enabled) { false }

          it "refuses with the reason rendered" do
            toggle

            expect(response).to have_http_status(:unprocessable_content)
            expect(response.body).to include("Steam News is part of Feeds. Turn Feeds on first.")
            expect(config.enabled_plugin_keys).not_to include(:steam_news)
          end

          context "without a Turbo Stream" do
            let(:headers) { {} }

            it "redirects back with the reason as an alert" do
              toggle

              expect(response).to redirect_to(plugin_path)
              expect(flash[:alert]).to be_present
            end
          end
        end

        context "when toggled from the overview" do
          let(:extra_params) { {from_overview: "1"} }
          let(:headers) { {} }

          it "redirects to the Feeds page" do
            toggle

            expect(response).to redirect_to(server_feeds_path(guild.id))
            expect(flash[:notice]).to eq("Steam News settings saved.")
          end
        end
      end
    end
  end
end
