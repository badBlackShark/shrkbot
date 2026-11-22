# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::TwitchCategory::TypeFields do
  include_context "component view context"

  subject(:html) { described_class.new(subscription:, event_type:, event: nil).render_in(view_context) { "MARKER" } }

  let(:subscription) { build(:feed_subscription, :twitch_category) }
  let(:event_type) { "Integrations::Twitch::StreamStarted" }
  let(:document) { Nokogiri::HTML.fragment(html) }

  it "has the channel override but no role override, since the follow has one role" do
    expect(document.css("select").map { |select| select["name"] }).to eq(["subscription[choices][#{event_type}][channel_id]"])
    expect(document.text).not_to include("Role override")
  end

  it "toggles the viewer count and the preview frame" do
    expect(document.css("input[type=checkbox]").map { |box| box["name"] }).to eq(%w[subscription[show_viewers] subscription[show_preview_frame]])
    expect(document.text).to include("Show the viewer count", "Show a preview frame")
  end

  it "puts the message fields between the toggles and what happens once the post is done" do
    expect(html.index("show_preview_frame")).to be < html.index("MARKER")
    expect(html.index("MARKER")).to be < html.index("live_end_mode")
    expect(html.index("live_end_mode")).to be < html.index("subscription[switched_away]")
  end
end
