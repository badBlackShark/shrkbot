# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::Announcement do
  subject(:announcement) { described_class.new(event:, subscription:, image_url:) }

  let(:profile_image) { "https://static-cdn.jtvnw.net/jtv_user_pictures/shrkbot-profile_image-300x300.png" }
  let(:watch) { create(:integration_watch, :twitch, image_url: profile_image) }
  let(:role_id) { 4242 }
  let(:subscription) { create(:feed_subscription, :twitch, watch:) }
  let(:template) { nil }
  let(:category_name) { "Hades II" }
  let(:event) { create(:twitch_stream_started_event, watch:, category_name:) }
  let(:image_url) { nil }

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
    let(:category) { Bot::Discord::Components.text("Streaming **Hades II**") }

    it "is purple" do
      expect(container[:accent_color]).to eq(0x9146ff)
    end

    it "leads with the role mention" do
      expect(lead).to eq(Bot::Discord::Components.text("<@&4242>"))
    end

    it "shows the eyebrow, heading and category beside the profile picture" do
      expect(container[:components].first).to eq(
        Bot::Discord::Components.section(
          [eyebrow, heading, category],
          accessory: Bot::Discord::Components.thumbnail(profile_image)
        )
      )
    end

    context "when the channel has no category" do
      let(:category_name) { nil }

      it "drops the category line" do
        expect(container[:components].first).to eq(
          Bot::Discord::Components.section([eyebrow, heading], accessory: Bot::Discord::Components.thumbnail(profile_image))
        )
      end
    end

    context "when the watch has no profile picture" do
      let(:profile_image) { nil }

      it "puts the texts straight into the container" do
        expect(container[:components]).to eq([eyebrow, heading, category])
      end
    end

    context "with an image" do
      let(:image_url) { "https://cdn.test/preview.jpg" }

      it "ends with a media gallery of it" do
        expect(container[:components].last).to eq(Bot::Discord::Components.media_gallery([image_url]))
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
