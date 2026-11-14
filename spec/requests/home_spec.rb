# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home", type: :request do
  subject(:home) { get root_path }

  it "renders OK" do
    home

    expect(response).to have_http_status(:ok)
  end

  it "shows the hero tagline" do
    home

    expect(response.body).to include(I18n.t("views.home.tagline"))
  end

  it "links the bespoke plugins pitch to the bespoke plugins page" do
    home

    expect(response.body).to match(%r{<a href="/bespoke-plugins"[^>]*>#{I18n.t("views.home.bespoke_plugins_link")}</a>})
  end

  it "describes each plugin card with its catalog text" do
    home

    %i[roles welcomes logging moderation reminders lfg steam twitch].each do |key|
      expect(response.body).to include(CGI.escapeHTML(PluginCatalog.description(key)))
    end
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

  it "shows the version badge linking to a release" do
    allow(ReleaseInfo).to receive(:current).and_return(
      ReleaseInfo.new(number: "3.1.0", released_on: Date.new(2026, 7, 11))
    )
    home

    expect(response.body).to include("/releases/tag/3.1.0")
  end

  it "links every public plugin card to its preview page" do
    home

    %w[roles welcomes logging moderation reminders lfg steam twitch].each do |key|
      expect(response.body).to include(%(href="/preview/#{key}"))
    end
  end

  it "labels both sign-in buttons the same" do
    home

    expect(response.body.scan("Sign in with Discord").size).to eq(2)
  end

  it "offers the preview as the one way in that needs no Discord account" do
    home

    expect(response.body).to include('href="/preview"')
    expect(response.body).to include(I18n.t("views.home.preview"))
  end

  it "renders the footer link" do
    home

    expect(response.body).to include("free and open source")
  end
end
