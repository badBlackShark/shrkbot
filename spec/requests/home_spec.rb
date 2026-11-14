# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home", type: :request do
  subject(:home) { get root_path }

  let(:plugin_keys) { %i[roles welcomes logging moderation reminders lfg steam twitch] }
  let(:cards) { Nokogiri::HTML5(response.body).css("div.grid > a[href^='/preview/']") }

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

    plugin_keys.each do |key|
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

    expect(cards.map { |card| card["href"] }).to match_array(plugin_keys.map { |key| "/preview/#{key}" })
  end

  it "shows a card for every public top-level plugin in the catalog" do
    home

    top_level = PluginCatalog.all.select { |definition| definition.parent.nil? && !definition.bespoke }.map(&:key)
    expected = top_level - [:integrations] + PluginCatalog.sub_plugin_keys(:integrations) + PluginCatalog::GLOBAL_KEYS

    expect(cards.map { |card| card["href"].delete_prefix("/preview/").to_sym }).to match_array(expected)
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
