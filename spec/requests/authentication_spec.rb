# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication", type: :request do
  include_context "discord auth"

  describe "the Discord callback" do
    subject(:callback) { post "/auth/discord/callback" }

    it "signs the user in and redirects to the server picker" do
      expect { callback }.to change(User, :count).by(1)
      expect(session[:user_id]).to eq(User.find_by(discord_id: 12345).id)
      expect(callback).to redirect_to(servers_path)
    end

    it "resets the session on sign-in so a pre-auth session can't be fixed" do
      get servers_path
      before_id = session.id&.public_id

      callback

      expect(before_id).to be_present
      expect(session.id&.public_id).not_to eq(before_id)
    end
  end

  describe "signing out" do
    before do
      post "/auth/discord/callback"
    end

    it "clears the session" do
      delete logout_path
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(root_path)
    end
  end

  describe "token expiry on a server-scoped page" do
    let(:guild) { Bot::Discord::Guild.new(id: 900_000_005, name: "Token Test", owner: true, permissions: 0, icon: nil, member_count: 3) }

    before do
      post "/auth/discord/callback"
      create(:server_configuration, discord_id: guild.id)
      allow(Bot::Discord::UserGuilds).to receive(:call).and_raise(Bot::Discord::UserGuilds::Unauthorized)
    end

    it "renders the reauth page and stores the current path" do
      get server_logging_path(guild.id)
      expect(response.body).to include("Signing you back in")
      expect(session[:return_to]).to eq(server_logging_path(guild.id))
    end

    it "stores the picker as the return path for a non-GET request" do
      patch server_logging_path(guild.id), params: {logging: {channel_id: "", enabled: "0", actions: {}}}
      expect(session[:return_to]).to eq(servers_path)
    end

    it "returns the user to the stored path once the callback succeeds" do
      get server_logging_path(guild.id)
      post "/auth/discord/callback"
      expect(response).to redirect_to(server_logging_path(guild.id))
    end

    it "resets the session and redirects home on a second consecutive failure" do
      get server_logging_path(guild.id)
      get server_logging_path(guild.id)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
      expect(session[:reauth_attempted]).to be_nil
    end
  end

  describe "a failed sign-in" do
    it "redirects home with an alert" do
      get "/auth/failure"

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "the home page" do
    it "offers a sign-in button when signed out" do
      get root_path
      expect(response.body).to include("Sign in with Discord")
    end

    it "submits the sign-in natively so Turbo doesn't swallow the cross-origin Discord redirect" do
      get root_path
      expect(response.body).to include('data-turbo="false"')
    end

    it "redirects a signed-in user to the server picker" do
      post "/auth/discord/callback"
      get root_path

      expect(response).to redirect_to(servers_path)
    end
  end
end
