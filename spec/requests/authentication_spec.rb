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
      expect(response.body).to include("Continue with Discord")
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
