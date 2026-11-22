# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Twitch config", type: :request do
  include_context "plugin config request"

  let(:plugin_path) { server_twitch_path(guild.id) }

  it_behaves_like "a config page that requires sign-in"

  context "when signed in" do
    let!(:twitch_plugin) { create(:plugin, key: "twitch", name: "Twitch") }

    before do
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id)
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

        context "with its two sources" do
          let(:tabs) { Nokogiri::HTML(response.body).css("[data-controller=option-panels] [role=radio]").map { |tab| [tab.text, tab["aria-checked"]] } }
          let(:panels) { Nokogiri::HTML(response.body).css("[data-option-panels-target=panel]").to_h { |panel| [panel["data-value"], panel] } }

          it "offers channels and categories, each with its own list, and opens channels" do
            get plugin_path

            expect(tabs).to eq([["Channels", "true"], ["Categories", "false"]])
            expect(panels.fetch("twitch").text).to include("No channels yet")
            expect(panels.fetch("twitch_category").text).to include("No categories yet")
            expect(panels.fetch("twitch_category")).to have_attribute("hidden")
          end

          it "opens the tab the query names" do
            get plugin_path, params: {tab: "twitch_category"}

            expect(tabs).to eq([["Channels", "false"], ["Categories", "true"]])
            expect(panels.fetch("twitch")).to have_attribute("hidden")
            expect(panels.fetch("twitch_category")).not_to have_attribute("hidden")
          end

          it "keeps one config container for the plugin toggle to replace" do
            get plugin_path

            expect(Nokogiri::HTML(response.body).css("#twitch-config").size).to eq(1)
          end
        end

        context "with the enable toggle" do
          subject(:twitch_page) { get plugin_path }

          it "saves on change without a save bar" do
            twitch_page

            expect(response.body).to include("change->toggle#submit")
            expect(response.body).not_to include('data-controller="save-bar"')
          end
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

        it "re-renders both lists on the first tab, so the categories survive the toggle" do
          create(:feed_subscription, :twitch_category, server_configuration: config)

          toggle

          document = Nokogiri::HTML(response.body)
          expect(response.body).to include("Some Category")
          expect(document.css("[role=radio]").map { |tab| [tab.text, tab["aria-checked"]] }).to eq([["Channels", "true"], ["Categories", "false"]])
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
