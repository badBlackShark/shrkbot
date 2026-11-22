# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::Twitch::LiveToggles do
  include_context "component view context"

  subject(:document) { Nokogiri::HTML.fragment(described_class.new(subscription:).render_in(view_context)) }

  let(:subscription) { build(:feed_subscription, :twitch) }

  it "toggles the viewer count and the preview frame, marked for the preview" do
    expect(document.css("input[type=checkbox]").map { |box| box["name"] }).to eq(%w[subscription[show_viewers] subscription[show_preview_frame]])
    expect(document.css("[data-setting-toggle]").map { |toggle| toggle["data-setting-toggle"] }).to eq(%w[viewers image])
    expect(document.text).to include("Show the viewer count", "Show a preview frame")
  end
end
