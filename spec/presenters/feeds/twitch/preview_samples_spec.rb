# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::PreviewSamples do
  subject(:samples) { described_class.new(watch_name: "SomeStreamer", event_type:) }

  let(:event_type) { "Integrations::Twitch::ClipCreated" }

  describe "#value" do
    it "is the watch name for streamer" do
      expect(samples.value("streamer")).to eq("SomeStreamer")
    end

    it "reads the sample copy for every other name" do
      expect(samples.value(:clipper)).to eq("Jane Doe")
      expect(samples.value(:title)).to eq("That dodge")
    end
  end

  describe "#tokens" do
    it "maps each name to its sample" do
      expect(samples.tokens(%w[streamer category clipper])).to eq("streamer" => "SomeStreamer", "category" => "Hades II", "clipper" => "Jane Doe")
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

      it "words it like the live announcement" do
        expect(card).to include(eyebrow: "SomeStreamer · Live on Twitch", body: "Streaming Hades II\nStarted 2 hours ago", button: "Watch on Twitch")
      end
    end
  end

  describe "the end-mode cards" do
    let(:event_type) { "Integrations::Twitch::StreamStarted" }

    it "offers the VOD button only in the VOD mode" do
      expect(samples.end_mode_card("mark_ended_with_vod")).to include(eyebrow: "SomeStreamer · Was live on Twitch", button: "Watch the VOD")
      expect(samples.end_mode_card("mark_ended")[:button]).to be_nil
    end

    it "stamps the live card with when the stream ended when it is kept" do
      expect(samples.end_mode_card("keep")[:body]).to eq("Streaming Hades II\nStarted 2 hours ago\nStream ended 5 minutes ago")
    end

    it "has no card for a deleted post" do
      expect(samples.end_mode_card("delete")).to be_nil
    end
  end
end
