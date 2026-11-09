# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::TargetSourceLink do
  include_context "component view context"

  subject(:html) { described_class.new(url:, plugin_key:).render_in(view_context) }

  let(:link) { Nokogiri::HTML.fragment(html).at_css("a") }
  let(:plugin_key) { :steam }
  let(:url) { "https://store.steampowered.com/app/1145350/" }

  it "opens the source in a new tab without leaking the opener" do
    expect(link).to have_attributes(text: "Open on Steam")
    expect(link["href"]).to eq(url)
    expect(link["target"]).to eq("_blank")
    expect(link["rel"]).to eq("noopener noreferrer")
  end

  context "with Twitch" do
    let(:plugin_key) { :twitch }
    let(:url) { "https://www.twitch.tv/twitchdev" }

    it "is labelled for Twitch" do
      expect(link.text).to eq("Open on Twitch")
    end
  end

  context "without a url" do
    let(:url) { nil }

    it "renders nothing" do
      expect(html).to be_blank
    end
  end
end
