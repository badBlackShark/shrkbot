# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Server picker", type: :request do
  include_context "discord auth"

  describe "GET /servers" do
    subject(:get_servers) { get servers_path }

    context "when signed out" do
      it "redirects to the sign-in page" do
        get_servers
        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in" do
      let(:present_guild) { Bot::Discord::Guild.new(id: 900_000_001, name: "Dev Refuge", owner: true, permissions: 0, icon: "icyhash", member_count: 2481) }
      let(:absent_guild) { Bot::Discord::Guild.new(id: 900_000_002, name: "Speedrun HQ", owner: false, permissions: 0x20, icon: nil, member_count: 1) }
      let(:unmanaged_guild) { Bot::Discord::Guild.new(id: 900_000_003, name: "Lurker Lounge", owner: false, permissions: 0, icon: nil) }
      let(:countless_guild) { Bot::Discord::Guild.new(id: 900_000_004, name: "Mystery Server", owner: true, permissions: 0, icon: nil) }

      before do
        post "/auth/discord/callback"
        create(:server_configuration, discord_id: present_guild.id)
        allow(Bot::Discord::UserGuilds).to receive(:call).and_return([present_guild, absent_guild, unmanaged_guild, countless_guild])
      end

      it "renders a server even when Discord omits its member count" do
        get_servers
        expect(response.body).to include("Mystery Server")
      end

      it "orders servers by member count, largest first" do
        get_servers
        expect(response.body.index("Speedrun HQ")).to be < response.body.index("Mystery Server")
      end

      it "lists a managed server the bot is already in, with its icon" do
        get_servers
        expect(response.body).to include("Dev Refuge")
        expect(response.body).to include("cdn.discordapp.com/icons/900000001/icyhash.png")
      end

      it "shows the member count and how many plugins are on" do
        get_servers
        expect(response.body).to include("2,481 members")
        expect(response.body).to include("0 plugins enabled")
      end

      context "with enabled plugins" do
        before do
          config = ServerConfiguration.find_by(discord_id: present_guild.id)
          config.create_logging_setting!(channel_id: 999)
          logging = create(:plugin, key: "logging", name: "Logging")
          create(:plugin_activation, server_configuration: config, plugin: logging, enabled: true)
        end

        it "counts them in the badge" do
          get_servers
          expect(response.body).to include("1 plugin enabled")
        end
      end

      it "frames the page in the app shell with a way to log out" do
        get_servers
        expect(response.body).to include("Log out")
        expect(response.body).to include("Toggle dark mode")
      end

      context "when the user has a display name and avatar" do
        let(:auth) do
          OmniAuth::AuthHash.new(
            provider: "discord",
            uid: "12345",
            info: {name: "shrk"},
            credentials: {token: "discord-access-token"},
            extra: {raw_info: {"global_name" => "Shrk Display", "avatar" => "avahash"}}
          )
        end

        it "shows them in the app shell" do
          get_servers
          expect(response.body).to include("Shrk Display")
          expect(response.body).to include("cdn.discordapp.com/avatars/12345/avahash.png")
        end
      end

      it "offers an invite for a managed server without the bot" do
        get_servers
        expect(response.body).to include("Speedrun HQ").and include("Invite shrkbot")
        expect(response.body).to include("1 member")
      end

      it "hides servers the user cannot manage" do
        get_servers
        expect(response.body).not_to include("Lurker Lounge")
      end

      context "with no manageable servers" do
        before do
          allow(Bot::Discord::UserGuilds).to receive(:call).and_return([unmanaged_guild])
        end

        it "shows the empty state" do
          get_servers
          expect(response.body).to include("in any of your servers yet")
        end
      end

      context "when Discord cannot be reached" do
        before do
          allow(Bot::Discord::UserGuilds).to receive(:call).and_raise(Bot::Discord::UserGuilds::Error)
        end

        it "renders the error state without raising" do
          get_servers
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("reach Discord")
        end
      end

      context "when the Discord access token has expired" do
        before do
          allow(Bot::Discord::UserGuilds).to receive(:call).and_raise(Bot::Discord::UserGuilds::Unauthorized)
        end

        it "kicks off automatic re-authentication" do
          get_servers
          expect(response.body).to include("Signing you back in")
          expect(session[:reauth_attempted]).to be(true)
        end

        it "falls back to the error state instead of looping if re-auth still fails" do
          get servers_path
          get servers_path
          expect(response.body).to include("reach Discord")
          expect(session[:reauth_attempted]).to be_nil
        end
      end
    end
  end
end
