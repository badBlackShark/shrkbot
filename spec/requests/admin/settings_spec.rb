# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin settings", type: :request do
  include_context "discord auth"

  let(:turbo) { {headers: {"Accept" => "text/vnd.turbo-stream.html"}} }

  context "when signed out" do
    it "redirects to the sign-in page" do
      get admin_settings_path
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in as a non-owner" do
    before do
      allow(Bot::Config).to receive(:owner_id).and_return("99999")
      post "/auth/discord/callback"
    end

    describe "GET /admin/settings" do
      it "redirects to the server picker with an alert" do
        get admin_settings_path
        expect(response).to redirect_to(servers_path)
        expect(flash[:alert]).to be_present
      end
    end

    describe "PATCH /admin/settings" do
      it "redirects without changing the setting" do
        BotSetting.owner_error_dms = false
        patch admin_settings_path, params: {owner_error_dms: "1"}, **turbo
        expect(response).to redirect_to(servers_path)
        expect(BotSetting.owner_error_dms?).to be(false)
      end
    end
  end

  context "when signed in as the owner" do
    before do
      allow(Bot::Config).to receive(:owner_id).and_return("12345")
      post "/auth/discord/callback"
    end

    describe "GET /admin/settings" do
      it "renders the settings page with the toggle card" do
        get admin_settings_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("owner-dm-card")
      end
    end

    describe "PATCH /admin/settings" do
      context "with turbo-stream" do
        it "flips the setting and responds with turbo-stream" do
          BotSetting.owner_error_dms = false
          patch admin_settings_path, params: {owner_error_dms: "1"}, **turbo
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(BotSetting.owner_error_dms?).to be(true)
        end

        it "turns the setting back off" do
          BotSetting.owner_error_dms = true
          patch admin_settings_path, params: {owner_error_dms: "0"}, **turbo
          expect(response.body).to include(I18n.t("admin.settings.dms_disabled"))
          expect(BotSetting.owner_error_dms?).to be(false)
        end
      end

      context "without turbo-stream" do
        it "redirects back to the settings page" do
          patch admin_settings_path, params: {owner_error_dms: "1"}
          expect(response).to redirect_to(admin_settings_path)
        end
      end
    end
  end
end
