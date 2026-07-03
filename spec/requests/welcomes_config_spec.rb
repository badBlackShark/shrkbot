# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Welcomes config", type: :request do
  include_context "discord auth"

  let(:guild) { Discord::Guild.new(id: 900_000_001, name: "Dev Refuge", owner: true, permissions: 0, icon: nil, member_count: 5) }
  let(:config) { ServerConfiguration.find_by(discord_id: guild.id) }
  let(:turbo) { {headers: {"Accept" => "text/vnd.turbo-stream.html"}} }

  context "when signed out" do
    it "redirects to the sign-in page" do
      get server_welcomes_path(900_000_001)
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in" do
    let!(:welcomes) { create(:plugin, key: "welcomes", name: "Welcomes") }

    before do
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id)
      config.create_welcome_settings!
      allow(Discord::UserGuilds).to receive(:call).and_return([guild])
    end

    context "without proving the server is manageable this session" do
      it "redirects to the picker" do
        get server_welcomes_path(guild.id)
        expect(response).to redirect_to(servers_path)
      end
    end

    context "after loading the dashboard authorizes the server" do
      before { get server_path(guild.id) }

      describe "GET /servers/:server_id/welcomes" do
        it "renders the config page in the app shell" do
          get server_welcomes_path(guild.id)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Welcomes")
          expect(response.body).to include("Join message")
          expect(response.body).to include("Live preview")
        end

        it "renders the save bar wired to the form" do
          get server_welcomes_path(guild.id)
          expect(response.body).to include("save-bar").and include("Unsaved changes")
          expect(response.body).to include("save-bar#discard")
          expect(response.body).to include("turbo:submit-end-&gt;save-bar#saved").or include("turbo:submit-end->save-bar#saved")
        end

        it "renders the plugin sidebar with a link to the other config page" do
          get server_welcomes_path(guild.id)
          expect(response.body).to include("<aside").and include("Plugins")
          expect(response.body).to include(server_logging_path(guild.id))
          expect(response.body).to include('aria-current="page"')
        end

        it "labels the live preview with the saved channel" do
          create(:server_channel, server_configuration: config, name: "general", discord_id: 111)
          config.welcome_settings.update!(channel_id: 111)
          get server_welcomes_path(guild.id)
          expect(response.body).to include("# general")
        end

        it "renders without a preview channel label when the saved channel no longer exists" do
          config.welcome_settings.update!(channel_id: 999)
          get server_welcomes_path(guild.id)
          expect(response).to have_http_status(:ok)
        end

        it "offers only text channels in the picker" do
          create(:server_channel, server_configuration: config, name: "general", discord_id: 111, channel_type: 0)
          create(:server_channel, server_configuration: config, name: "lounge", discord_id: 222, channel_type: 2)
          get server_welcomes_path(guild.id)
          expect(response.body).to include(">general<")
          expect(response.body).not_to include("lounge")
        end
      end

      describe "PATCH /servers/:server_id/welcomes" do
        before { create(:server_channel, server_configuration: config, name: "general", discord_id: 111) }

        it "saves the settings and enables the plugin in one request" do
          patch server_welcomes_path(guild.id),
            params: {welcomes: {channel_id: 111, join_message: "hi {user}", leave_message: "", enabled: "1"}},
            **turbo
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(config.welcome_settings.reload.channel_id).to eq(111)
          expect(config.plugins.enabled.exists?(key: :welcomes)).to be(true)
          expect(response.body).to include("saved")
        end

        it "re-renders the form with an inline error when enabling without a channel" do
          patch server_welcomes_path(guild.id),
            params: {welcomes: {channel_id: "", join_message: "", leave_message: "", enabled: "1"}},
            **turbo
          expect(response).to have_http_status(:unprocessable_content)
          expect(config.plugins.enabled.exists?(key: :welcomes)).to be(false)
          expect(response.body).to include("welcomes-config")
          expect(response.body).to include("settings to be configured")
        end

        it "saves messages without enabling and reports success" do
          patch server_welcomes_path(guild.id),
            params: {welcomes: {channel_id: "", join_message: "hello", leave_message: "", enabled: "0"}},
            **turbo
          expect(config.welcome_settings.reload.join_message).to eq("hello")
          expect(response.body).to include("saved")
        end

        it "falls back to a redirect without Turbo" do
          patch server_welcomes_path(guild.id),
            params: {welcomes: {channel_id: 111, join_message: "hi", leave_message: "", enabled: "1"}}
          expect(response).to redirect_to(server_welcomes_path(guild.id))
        end

        it "redirects with an alert when a non-Turbo save fails" do
          patch server_welcomes_path(guild.id),
            params: {welcomes: {channel_id: "", join_message: "", leave_message: "", enabled: "1"}}
          expect(response).to redirect_to(server_welcomes_path(guild.id))
          expect(flash[:alert]).to be_present
        end
      end
    end
  end
end
