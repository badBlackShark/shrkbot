require "rails_helper"

RSpec.describe "Home", type: :request do
  subject(:home) { get root_path }

  it "renders the styled sign-in page" do
    home

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Sign in with Discord")
  end

  it "uses the brand display type for the wordmark" do
    home

    expect(response.body).to include("font-display")
  end

  it "wires up the theme toggle" do
    home

    expect(response.body).to include('data-controller="theme"')
    expect(response.body).to include("theme#toggle")
  end
end
