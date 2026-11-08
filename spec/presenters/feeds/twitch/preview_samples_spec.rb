# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::PreviewSamples do
  subject(:samples) { described_class.new(watch_name: "SomeStreamer", event_type:) }

  let(:event_type) { "Integrations::Twitch::ClipCreated" }

  describe "#tokens" do
    it "maps the watch name for streamer and the sample copy for every other name" do
      expect(samples.tokens(%w[streamer category clipper title])).to eq(
        "streamer" => "SomeStreamer",
        "category" => "Hades II",
        "clipper" => "Jane Doe",
        "title" => "That dodge"
      )
    end
  end

  describe "#card" do
    subject(:card) { samples.card }

    it "words a clip like the clip announcement" do
      expect(card).to include(
        eyebrow: "SomeStreamer · New clip on Twitch",
        title: "That dodge",
        body: "Clipped by Jane Doe from Hades II\n30 s · made 5 minutes ago",
        button: "Watch the clip"
      )
    end

    context "with a highlight" do
      let(:event_type) { "Integrations::Twitch::HighlightPublished" }

      it "words it like the video announcement, with the length as the body" do
        expect(card).to include(eyebrow: "SomeStreamer · New highlight on Twitch", body: "About 1 h 30 min", button: "Watch on Twitch")
      end
    end

    context "with a live stream" do
      let(:event_type) { "Integrations::Twitch::StreamStarted" }

      it "words it like the live announcement, carrying the viewer and plain stats lines for the toggle to switch" do
        expect(card).to include(
          eyebrow: "SomeStreamer · Live on Twitch",
          body: [
            {text: "Streaming Hades II", class: nil},
            {text: "1,234 watching · started 2 hours ago", class: described_class::VIEWERS_SHOWN},
            {text: "Started 2 hours ago", class: described_class::VIEWERS_HIDDEN}
          ],
          button: "Watch on Twitch"
        )
      end
    end
  end

  describe "the end-mode cards" do
    let(:event_type) { "Integrations::Twitch::StreamStarted" }

    it "offers the VOD button only in the VOD mode" do
      expect(samples.end_mode_card("mark_ended_with_vod")).to include(eyebrow: "SomeStreamer · Was live on Twitch", button: "Watch the VOD")
      expect(samples.end_mode_card("mark_ended")[:button]).to be_nil
    end

    it "carries the peak and plain ended lines on both ended cards" do
      lines = [
        {text: "Streamed Hades II for about 2 h", class: nil},
        {text: "At least 2,345 viewers at the peak · ended 5 minutes ago", class: described_class::VIEWERS_SHOWN},
        {text: "Ended 5 minutes ago", class: described_class::VIEWERS_HIDDEN}
      ]
      expect(samples.end_mode_card("mark_ended_with_vod")[:body]).to eq(lines)
      expect(samples.end_mode_card("mark_ended")[:body]).to eq(lines)
    end

    it "ends the kept live card with when the stream ended" do
      expect(samples.end_mode_card("keep")[:body]).to eq(
        samples.card[:body] + [{text: "Stream ended 5 minutes ago", class: nil}]
      )
    end

    it "has no card for a deleted post" do
      expect(samples.end_mode_card("delete")).to be_nil
    end
  end

  describe "#switched_card" do
    subject(:card) { samples.switched_card }

    let(:event_type) { "Integrations::Twitch::StreamStarted" }

    it "words it like the switched announcement, with the new category and when the stream started" do
      expect(card).to include(
        eyebrow: "SomeStreamer · Live on Twitch",
        title: "Hades II, first run",
        body: [{text: "Switched to Just Chatting", class: nil}, {text: "Started 2 hours ago", class: nil}],
        button: "Watch on Twitch"
      )
    end
  end
end
