# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Integrations config", type: :request do
  include_context "plugin config request"

  let(:plugin_path) { server_integrations_path(guild.id) }

  it_behaves_like "a config page that requires sign-in"

  context "when signed in" do
    let!(:steam_plugin) { create(:plugin, key: "steam", name: "Steam") }

    before do
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id)
      allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
    end

    it_behaves_like "a config page that requires a manageable server"

    context "after loading the dashboard authorizes the server" do
      before { get server_path(guild.id) }

      describe "GET /servers/:server_id/integrations" do
        it "lists the Steam sub-plugin with a link to its page" do
          get plugin_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Steam")
          expect(response.body).to include(server_steam_path(guild.id))
        end

        it "renders no enable toggle" do
          get plugin_path

          expect(response.body).not_to include('name="integrations[enabled]"')
        end

        it "lists the sources without a list heading" do
          get plugin_path

          expect(response.body).not_to include("Sub-plugins")
        end
      end
    end
  end
end
