require "rails_helper"

RSpec.describe "Server picker", type: :request do
  let(:auth) do
    OmniAuth::AuthHash.new(
      provider: "discord",
      uid: "12345",
      info: {name: "shrk"},
      credentials: {token: "discord-access-token"}
    )
  end

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:discord] = auth
    Rails.application.env_config["omniauth.auth"] = auth
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:discord] = nil
    Rails.application.env_config.delete("omniauth.auth")
  end

  describe "GET /servers" do
    subject(:get_servers) { get servers_path }

    context "when signed out" do
      it "redirects to the sign-in page" do
        get_servers
        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in" do
      let(:present_guild) { Discord::Guild.new(id: 900_000_001, name: "Dev Refuge", owner: true, permissions: 0, icon: "icyhash") }
      let(:absent_guild) { Discord::Guild.new(id: 900_000_002, name: "Speedrun HQ", owner: false, permissions: 0x20, icon: nil) }
      let(:unmanaged_guild) { Discord::Guild.new(id: 900_000_003, name: "Lurker Lounge", owner: false, permissions: 0, icon: nil) }

      before do
        post "/auth/discord/callback"
        create(:server_configuration, discord_id: present_guild.id)
        allow(Discord::UserGuilds).to receive(:call).and_return([present_guild, absent_guild, unmanaged_guild])
      end

      it "lists a managed server the bot is already in, with its icon" do
        get_servers
        expect(response.body).to include("Dev Refuge")
        expect(response.body).to include("cdn.discordapp.com/icons/900000001/icyhash.png")
      end

      it "offers a way to sign out" do
        get_servers
        expect(response.body).to include("Sign out")
      end

      it "offers an invite for a managed server without the bot" do
        get_servers
        expect(response.body).to include("Speedrun HQ").and include("Invite shrkbot")
      end

      it "hides servers the user cannot manage" do
        get_servers
        expect(response.body).not_to include("Lurker Lounge")
      end

      context "with no manageable servers" do
        before { allow(Discord::UserGuilds).to receive(:call).and_return([unmanaged_guild]) }

        it "shows the empty state" do
          get_servers
          expect(response.body).to include("in any of your servers yet")
        end
      end

      context "when Discord cannot be reached" do
        before { allow(Discord::UserGuilds).to receive(:call).and_raise(Discord::UserGuilds::Error) }

        it "renders the error state without raising" do
          get_servers
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("reach Discord")
        end
      end

      context "when the Discord access token has expired" do
        before { allow(Discord::UserGuilds).to receive(:call).and_raise(Discord::UserGuilds::Unauthorized) }

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
