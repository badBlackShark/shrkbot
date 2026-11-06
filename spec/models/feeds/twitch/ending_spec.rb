# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::Ending do
  subject(:announcement) { described_class.announcement(event: ended, subscription:) }

  let(:watch) { create(:integration_watch, :twitch) }
  let(:subscription) { create(:feed_subscription, :twitch, watch:) }
  let(:session) { "40000000001" }
  let!(:started) { create(:twitch_stream_started_event, watch:, session:, occurred_at: 3.hours.ago) }
  let!(:updated) { create(:twitch_stream_updated_event, watch:, session:, title: "Boss rush", occurred_at: 1.hour.ago) }
  let!(:ended) { create(:twitch_stream_ended_event, watch:, session:, occurred_at: Time.current) }
  let(:live_end_mode) { "mark_ended_with_vod" }

  before do
    subscription.settings.update!(live_end_mode:)
    allow(Feeds::Twitch::LiveImage).to receive(:for).and_return("https://box.art/x.jpg")
    allow(Feeds::Twitch::Vod).to receive(:url_for).with(ended).and_return("https://www.twitch.tv/videos/1")
  end

  context "when keeping the card" do
    let(:live_end_mode) { "keep" }

    it "is the live card of the last live event, stamped with the end" do
      expect(announcement).to be_a(Feeds::Twitch::Announcement)
      expect(announcement.card).to eq(
        Feeds::Twitch::Announcement.new(event: updated, subscription:, image_url: "https://box.art/x.jpg", ended_at: ended.ended_at).card
      )
    end
  end

  context "when marking the stream ended" do
    let(:live_end_mode) { "mark_ended" }

    it "is the ended card without a VOD, and never looks one up" do
      expect(announcement.card).to eq(
        Feeds::Twitch::EndedAnnouncement.new(event: ended, subscription:, history: Feeds::Twitch::TitleHistory.for(ended)).card
      )
      expect(Feeds::Twitch::Vod).not_to have_received(:url_for)
    end
  end

  context "when marking the stream ended with its VOD" do
    it "is the ended card with the VOD" do
      expect(announcement.card).to eq(
        Feeds::Twitch::EndedAnnouncement.new(
          event: ended,
          subscription:,
          history: Feeds::Twitch::TitleHistory.for(ended),
          vod_url: "https://www.twitch.tv/videos/1"
        ).card
      )
    end
  end
end
