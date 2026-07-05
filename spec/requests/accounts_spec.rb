# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accounts", type: :request do
  include_context "discord auth"

  context "when signed out" do
    it "GET /account redirects to root" do
      get account_path
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in" do
    before { post "/auth/discord/callback" }

    describe "GET /account" do
      it "responds ok" do
        get account_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "DELETE /account" do
      let(:user) { User.find_by(discord_id: 12345) }
      let!(:reminder) { create(:reminder, user_id: user.discord_id) }

      it "destroys the user" do
        expect { delete account_path }.to change(User, :count).by(-1)
      end

      it "deletes the user's reminders" do
        expect { delete account_path }.to change(Reminders::Reminder, :count).by(-1)
      end

      it "redirects to root" do
        delete account_path
        expect(response).to redirect_to(root_path)
      end

      it "clears the session so a subsequent authenticated request redirects" do
        delete account_path
        get account_path
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
