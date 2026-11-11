# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::TargetBanner do
  include_context "component view context"

  subject(:document) { Nokogiri::HTML.fragment(described_class.new(watch:, plugin_key: :twitch).render_in(view_context)) }

  let(:watch) { build(:integration_watch, :twitch, name: "TwitchDev", url: "https://www.twitch.tv/twitchdev") }

  it "shows the target card with a link to the source" do
    expect(document.at_css("h1").text).to eq("TwitchDev")
    expect(document.at_css("a[href='https://www.twitch.tv/twitchdev']").text).to eq("Open on Twitch")
  end
end
