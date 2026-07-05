# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Legal pages", type: :request do
  describe "GET /privacy" do
    subject(:privacy) { get privacy_policy_path }

    it "responds ok while signed out" do
      privacy

      expect(response).to have_http_status(:ok)
    end

    it "includes the privacy policy title" do
      privacy

      expect(response.body).to include("Privacy policy")
    end

    context "when signed out" do
      it "shows the sign-in button and not the dashboard link" do
        privacy

        expect(response.body).to include("Sign in with Discord")
        expect(response.body).not_to include('href="/servers"')
      end
    end

    context "when signed in" do
      include_context "discord auth"

      before { post "/auth/discord/callback" }

      it "shows the dashboard link and not the sign-in button" do
        privacy

        expect(response.body).to include('href="/servers"')
        expect(response.body).not_to include("Sign in with Discord")
      end
    end
  end

  describe "GET /terms" do
    subject(:terms) { get terms_of_service_path }

    it "responds ok while signed out" do
      terms

      expect(response).to have_http_status(:ok)
    end

    it "includes the terms of service title" do
      terms

      expect(response.body).to include("Terms of service")
    end
  end

  describe "GET /imprint" do
    subject(:imprint) { get imprint_path }

    it "responds ok while signed out" do
      imprint

      expect(response).to have_http_status(:ok)
    end

    it "includes the imprint title" do
      imprint

      expect(response.body).to include("Imprint")
    end
  end
end
