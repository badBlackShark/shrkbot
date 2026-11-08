# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::ClipAnnouncement do
  subject(:announcement) { described_class.new(event:, subscription:, category:) }

  let(:profile_image) { "https://static-cdn.jtvnw.net/jtv_user_pictures/shrkbot-profile_image-300x300.png" }
  let(:watch) { create(:integration_watch, :twitch, image_url: profile_image) }
  let(:subscription) { create(:feed_subscription, :twitch, watch:) }
  let(:template) { nil }
  let(:notification_template) { nil }
  let(:category) { Integrations::Twitch::Game.new(id: "18122", name: "Hades II", box_art_url: nil) }
  let(:occurred_at) { Time.zone.parse("2026-11-01 09:00:00") }
  let(:event_type) { "Integrations::Twitch::FeaturedClipPublished" }
  let(:event) { create(:twitch_featured_clip_published_event, watch:, occurred_at:) }
  let(:role_column) { :featured_clips_role_id }

  before do
    subscription.settings.update!(role_column => 4242)
    create(:feed_subscribed_event, subscription:, event_type:, template:, notification_template:)
  end

  describe "#subject" do
    subject(:subject_line) { announcement.subject }

    it "is the role and the default text" do
      expect(subject_line).to eq("<@&4242> New featured clip from shrkbot_dev: Ghost form")
    end

    context "with a notification text" do
      let(:notification_template) { "{clipper} clipped {streamer} in {category}: {title}" }

      it "fills the clip tokens" do
        expect(subject_line).to eq("<@&4242> Annonsu clipped shrkbot_dev in Hades II: Ghost form")
      end

      context "without a category" do
        let(:category) { nil }

        it "leaves the category empty" do
          expect(subject_line).to eq("<@&4242> Annonsu clipped shrkbot_dev in : Ghost form")
        end
      end
    end

    context "with a new clip" do
      let(:event_type) { "Integrations::Twitch::ClipCreated" }
      let(:event) { create(:twitch_clip_created_event, watch:, occurred_at:) }
      let(:role_column) { :clips_role_id }

      it "says new clip" do
        expect(subject_line).to eq("<@&4242> New clip from shrkbot_dev: Ghost form")
      end
    end
  end

  describe "#fallback" do
    it "ends with the clip link" do
      expect(announcement.fallback).to end_with("\n#{event.url}")
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
    let(:eyebrow) { Bot::Discord::Components.text("-# shrkbot_dev · Featured clip on Twitch") }
    let(:heading) { Bot::Discord::Components.text("## Ghost form") }
    let(:details) { Bot::Discord::Components.text("Clipped by Annonsu from **Hades II**\n-# 60 s · made <t:#{occurred_at.to_i}:R>") }
    let(:image) { Bot::Discord::Components.media_gallery([event.thumbnail_url]) }

    it "is purple" do
      expect(container[:accent_color]).to eq(0x9146ff)
    end

    it "leads with the role mention" do
      expect(lead).to eq(Bot::Discord::Components.text("<@&4242>"))
    end

    it "shows the eyebrow, heading and details beside the profile picture, then the thumbnail" do
      expect(container[:components]).to eq(
        [
          Bot::Discord::Components.section([eyebrow, heading, details], accessory: Bot::Discord::Components.thumbnail(profile_image)),
          image
        ]
      )
    end

    context "with a new clip" do
      let(:event_type) { "Integrations::Twitch::ClipCreated" }
      let(:event) { create(:twitch_clip_created_event, watch:, occurred_at:) }
      let(:role_column) { :clips_role_id }
      let(:eyebrow) { Bot::Discord::Components.text("-# shrkbot_dev · New clip on Twitch") }

      it "names the new clip in the eyebrow" do
        expect(container[:components].first[:components].first).to eq(eyebrow)
      end
    end

    context "without a category" do
      let(:category) { nil }
      let(:details) { Bot::Discord::Components.text("Clipped by Annonsu\n-# 60 s · made <t:#{occurred_at.to_i}:R>") }

      it "drops the from part" do
        expect(container[:components].first[:components].last).to eq(details)
      end
    end

    context "when the watch has no profile picture" do
      let(:profile_image) { nil }

      it "puts the texts straight into the container" do
        expect(container[:components]).to eq([eyebrow, heading, details, image])
      end
    end

    it "links the clip" do
      expect(action_row[:components]).to eq(
        [Bot::Discord::Components.link_button(url: event.url, label: "Watch the clip")]
      )
    end
  end
end
