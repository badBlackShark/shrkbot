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
end
