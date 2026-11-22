# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::TwitchCategory::PreviewSamples do
  subject(:samples) { described_class.new(watch_name: "Hades II", event_type: "Integrations::Twitch::StreamStarted") }

  it "shows a sample streamer, not the followed category, as the channel" do
    expect(samples.tokens(%w[streamer category title])).to eq(
      "streamer" => "SomeStreamer",
      "category" => "Hades II",
      "title" => "Hades II, first run"
    )
    expect(samples.card.fetch(:eyebrow)).to start_with("SomeStreamer")
  end
end
