# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::Announcement do
  subject(:announcement) { described_class.new(event:, subscription:, image_url:, ended_at:) }

  let(:profile_image) { "https://static-cdn.jtvnw.net/jtv_user_pictures/shrkbot-profile_image-300x300.png" }
  let(:watch) { create(:integration_watch, :twitch, image_url: profile_image) }
  let(:role_id) { 4242 }
  let(:subscription) { create(:feed_subscription, :twitch, watch:) }
  let(:template) { nil }
  let(:category_name) { "Hades II" }
  let(:viewer_count) { nil }
  let(:started_at) { Time.zone.parse("2026-11-01 09:00:00") }
  let(:started_epoch) { started_at.to_i }
  let(:event) { create(:twitch_stream_started_event, watch:, category_name:, viewer_count:, started_at: started_at.iso8601) }
  let(:image_url) { nil }
  let(:ended_at) { nil }

  before do
    subscription.settings.update!(live_role_id: role_id)
    create(:feed_subscribed_event, subscription:, event_type: "Integrations::Twitch::StreamStarted", template:)
  end

  describe "#subject" do
    subject(:subject_line) { announcement.subject }

    it "is the role and the headline" do
      expect(subject_line).to eq("<@&4242> shrkbot_dev is live: Hades II blind run, day 3")
    end

    context "with a custom message" do
      let(:template) { "{streamer} streamt {category}!" }

      it "replaces the headline" do
        expect(subject_line).to eq("<@&4242> shrkbot_dev streamt Hades II!")
      end
    end

    context "with the title in a custom message" do
      let(:template) { "{title}" }

      it "replaces the headline with the stream title" do
        expect(subject_line).to eq("<@&4242> Hades II blind run, day 3")
      end
    end
  end

  describe "#fallback" do
    it "ends with the channel link" do
      expect(announcement.fallback).to end_with("\nhttps://www.twitch.tv/shrkbot_dev")
    end
  end

  describe "#attachments" do
    it "is nil" do
      expect(announcement.attachments).to be_nil
    end
  end

  describe "#card" do
    subject(:card) { announcement.card }

    let(:lead) { card[:components].first }
    let(:container) { card[:components].find { |component| component[:type] == Bot::Discord::Components::CONTAINER } }
    let(:action_row) { card[:components].last }
    let(:eyebrow) { Bot::Discord::Components.text("-# shrkbot_dev · Live on Twitch") }
    let(:heading) { Bot::Discord::Components.text("## Hades II blind run, day 3") }
    let(:details) { Bot::Discord::Components.text("Streaming **Hades II**\n-# Started <t:#{started_epoch}:R>") }

    it "is purple" do
      expect(container[:accent_color]).to eq(0x9146ff)
    end

    it "leads with the role mention" do
      expect(lead).to eq(Bot::Discord::Components.text("<@&4242>"))
    end

    it "shows the eyebrow, heading and details beside the profile picture" do
      expect(container[:components].first).to eq(
        Bot::Discord::Components.section(
          [eyebrow, heading, details],
          accessory: Bot::Discord::Components.thumbnail(profile_image)
        )
      )
    end

    context "when the channel has no category" do
      let(:category_name) { nil }

      it "keeps only the start time" do
        expect(container[:components].first[:components].last).to eq(
          Bot::Discord::Components.text("-# Started <t:#{started_epoch}:R>")
        )
      end
    end

    context "with a viewer count" do
      let(:viewer_count) { 1204 }

      it "shows it before the start time" do
        expect(container[:components].first[:components].last).to eq(
          Bot::Discord::Components.text("Streaming **Hades II**\n-# 1,204 watching · started <t:#{started_epoch}:R>")
        )
      end

      context "when the subscription hides viewers" do
        before do
          subscription.settings.update!(show_viewers: false)
        end

        it "shows only the start time" do
          expect(container[:components].first[:components].last).to eq(
            Bot::Discord::Components.text("Streaming **Hades II**\n-# Started <t:#{started_epoch}:R>")
          )
        end
      end
    end

    context "when the watch has no profile picture" do
      let(:profile_image) { nil }

      it "puts the texts straight into the container" do
        expect(container[:components]).to eq([eyebrow, heading, details])
      end
    end

    context "with an image" do
      let(:image_url) { "https://cdn.test/preview.jpg" }

      it "ends with a media gallery of it" do
        expect(container[:components].last).to eq(Bot::Discord::Components.media_gallery([image_url]))
      end
    end

    context "with an end time" do
      let(:image_url) { "https://cdn.test/preview.jpg" }
      let(:ended_at) { (started_at + 2.hours).iso8601 }

      it "closes the card with when the stream ended, after the image" do
        expect(container[:components].last).to eq(Bot::Discord::Components.text("-# Stream ended <t:#{(started_at + 2.hours).to_i}:R>"))
      end

      it "keeps the lead" do
        expect(lead).to eq(Bot::Discord::Components.text("<@&4242>"))
      end
    end

    context "without an image" do
      it "has no media gallery" do
        expect(container[:components].map { |block| block[:type] }).not_to include(Bot::Discord::Components::MEDIA_GALLERY)
      end
    end

    it "links the channel" do
      expect(action_row[:components]).to eq(
        [Bot::Discord::Components.link_button(url: "https://www.twitch.tv/shrkbot_dev", label: "Watch on Twitch")]
      )
    end
  end
end
