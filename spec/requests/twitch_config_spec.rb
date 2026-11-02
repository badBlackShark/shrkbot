# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Twitch config", type: :request do
  include_context "plugin config request"

  let(:plugin_path) { server_twitch_path(guild.id) }

  it_behaves_like "a config page that requires sign-in"

  context "when signed in" do
    let!(:integrations_plugin) { create(:plugin, key: "integrations", name: "Integrations") }
    let!(:twitch_plugin) { create(:plugin, key: "twitch", name: "Twitch") }

    before do
      allow(Integrations::Twitch::Client).to receive(:configured?).and_return(true)
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id)
      create(:plugin_activation, server_configuration: config, plugin: integrations_plugin, enabled: true)
      allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    end

    it_behaves_like "a config page that requires a manageable server"

    context "after loading the dashboard authorizes the server" do
      before { get server_path(guild.id) }

      describe "GET /servers/:server_id/twitch" do
        it "renders the empty state" do
          get plugin_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("No channels yet")
        end
      end

      describe "PATCH /servers/:server_id/twitch" do
        subject(:toggle) { patch plugin_path, params: {twitch: {enabled: "1"}}, **turbo }

        it "enables Twitch" do
          toggle

          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(response.body).to include("twitch-config")
          expect(config.enabled_plugin_keys).to include(:twitch)
        end

        context "when toggled from the overview" do
          subject(:toggle) { patch plugin_path, params: {twitch: {enabled: "1"}, from_overview: "1"} }

          it "redirects to the Integrations page" do
            toggle

            expect(response).to redirect_to(server_integrations_path(guild.id))
            expect(flash[:notice]).to eq(I18n.t("servers.twitch.saved"))
          end
        end
      end
    end
  end
end
