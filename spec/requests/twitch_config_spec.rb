# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Twitch config", type: :request do
  include_context "plugin config request"

  let(:plugin_path) { server_twitch_path(guild.id) }

  it_behaves_like "a config page that requires sign-in"

  context "when signed in" do
    let!(:integrations_plugin) { create(:plugin, key: "integrations", name: "Integrations") }
    let!(:twitch_plugin) { create(:plugin, key: "twitch", name: "Twitch") }
    let(:integrations_enabled) { true }

    before do
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id)
      create(:plugin_activation, server_configuration: config, plugin: integrations_plugin, enabled: integrations_enabled)
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

        context "with the page header" do
          subject(:twitch_page) { get plugin_path }

          let(:heading) { Nokogiri::HTML(response.body).at_css("h1").text.strip }

          it "carries Twitch's own title and description" do
            twitch_page

            expect(heading).to eq("Twitch")
            expect(response.body).to include("Announces when the Twitch channels you follow go live, and posts their highlights, uploads, and clips.")
          end
        end
      end

      describe "PATCH /servers/:server_id/twitch" do
        subject(:toggle) { patch plugin_path, params: {twitch: {enabled: "1"}}, **turbo }

        it "enables Twitch" do
          toggle

          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(response.body).to include(%(id="twitch-config"))
          expect(config.enabled_plugin_keys).to include(:twitch)
        end

        context "when Integrations is off" do
          let(:integrations_enabled) { false }
          let(:replaced) { Nokogiri::HTML.fragment(response.body).at_css("template").inner_html }

          it "refuses with the reason rendered inside the Twitch section" do
            toggle

            expect(response).to have_http_status(:unprocessable_content)
            expect(Nokogiri::HTML.fragment(replaced).at_css("#twitch-config").text).to include("Twitch is part of Integrations. Turn Integrations on first.")
            expect(config.enabled_plugin_keys).not_to include(:twitch)
          end
        end

        context "without a Turbo Stream" do
          subject(:toggle) { patch plugin_path, params: {twitch: {enabled: "1"}} }

          it "redirects back to the Twitch page, not the first feed source's" do
            toggle

            expect(response).to redirect_to(plugin_path)
          end
        end
      end
    end
  end
end
