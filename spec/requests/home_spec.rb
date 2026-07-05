# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home", type: :request do
  subject(:home) { get root_path }

  it "renders OK" do
    home

    expect(response).to have_http_status(:ok)
  end

  it "shows the hero headline" do
    home

    expect(response.body).to include("You pick the parts.")
  end

  it "uses the brand display type for the wordmark" do
    home

    expect(response.body).to include("font-display")
  end

  it "renders two sign-in forms pointing at /auth/discord" do
    home

    expect(response.body.scan('action="/auth/discord"').size).to eq(2)
  end

  it "links to the GitHub repo" do
    home

    expect(response.body).to include('href="https://github.com/badBlackShark/shrkbot"')
  end

  it "renders the four plugin cards" do
    home

    %w[Roles Welcomes Logging Reminders].each do |name|
      expect(response.body).to include(name)
    end
  end

  it "renders the more-plugins line" do
    home

    expect(response.body).to include(I18n.t("views.home.more_plugins"))
  end

  it "renders the marquee wrapper" do
    home

    expect(response.body).to include("plugin-marquee")
  end

  it "renders the footer link" do
    home

    expect(response.body).to include("free and open source")
  end
end
