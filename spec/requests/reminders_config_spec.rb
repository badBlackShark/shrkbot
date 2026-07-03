# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reminders config", type: :request do
  include_context "discord auth"

  let(:guild) { Discord::Guild.new(id: 900_000_001, name: "Dev Refuge", owner: true, permissions: 0, icon: nil, member_count: 5) }
  let(:config) { ServerConfiguration.find_by(discord_id: guild.id) }
  let(:turbo) { {headers: {"Accept" => "text/vnd.turbo-stream.html"}} }

  context "when signed out" do
    it "redirects to the sign-in page" do
      get server_reminders_path(900_000_001)
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in" do
    before do
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id)
      allow(Discord::UserGuilds).to receive(:call).and_return([guild])
    end

    context "without proving the server is manageable this session" do
      it "redirects to the picker" do
        get server_reminders_path(guild.id)
        expect(response).to redirect_to(servers_path)
      end
    end

    context "after loading the dashboard authorizes the server" do
      before { get server_path(guild.id) }

      describe "GET /servers/:server_id/reminders" do
        it "renders the config page with the force-DM toggle and callout" do
          get server_reminders_path(guild.id)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Force reminder delivery via DM")
          expect(response.body).to include("/remind")
        end

        it "shows the Global badge instead of an enable gate" do
          get server_reminders_path(guild.id)
          expect(response.body).to include("Global")
          expect(response.body).not_to include("enable-gate")
        end

        it "renders the save bar wired to the form" do
          get server_reminders_path(guild.id)
          expect(response.body).to include("save-bar").and include("Unsaved changes")
        end

        it "appears in the plugin sidebar as the active page" do
          get server_reminders_path(guild.id)
          expect(response.body).to include("<aside")
          expect(response.body).to include('aria-current="page"')
        end
      end

      describe "PATCH /servers/:server_id/reminders" do
        it "saves the setting and re-renders the form with a toast" do
          patch server_reminders_path(guild.id),
            params: {reminders: {force_dm_reminders: "1"}},
            **turbo
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(config.reload.force_dm_reminders).to be(true)
          expect(response.body).to include("reminders-config")
          expect(response.body).to include("saved")
        end

        it "falls back to a redirect without Turbo" do
          patch server_reminders_path(guild.id),
            params: {reminders: {force_dm_reminders: "0"}}
          expect(response).to redirect_to(server_reminders_path(guild.id))
          expect(flash[:notice]).to be_present
        end
      end
    end
  end
end
