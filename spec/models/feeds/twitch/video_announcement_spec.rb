# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::VideoAnnouncement do
  subject(:announcement) { described_class.new(event:, subscription:) }

  let(:profile_image) { "https://static-cdn.jtvnw.net/jtv_user_pictures/shrkbot-profile_image-300x300.png" }
  let(:watch) { create(:integration_watch, :twitch, image_url: profile_image) }
  let(:subscription) { create(:feed_subscription, :twitch, watch:) }
  let(:template) { nil }
  let(:event_type) { "Integrations::Twitch::HighlightPublished" }
  let(:event) { create(:twitch_highlight_published_event, watch:) }
  let(:role_column) { :highlights_role_id }

  before do
    subscription.settings.update!(role_column => 4242)
    create(:feed_subscribed_event, subscription:, event_type:, template:)
  end

  describe "#subject" do
    subject(:subject_line) { announcement.subject }

    it "is the role and the headline" do
      expect(subject_line).to eq("<@&4242> shrkbot_dev posted a highlight: Fragpunk early access, best rounds")
    end

    context "with a custom message" do
      let(:template) { "{streamer} has a new video: {title}" }

      it "replaces the headline" do
        expect(subject_line).to eq("<@&4242> shrkbot_dev has a new video: Fragpunk early access, best rounds")
      end
    end

    context "with tokens a video has no value for" do
      let(:template) { "{streamer} [{category}] ({clipper})" }

      it "leaves them empty instead of printing them" do
        expect(subject_line).to eq("<@&4242> shrkbot_dev [] ()")
      end
    end

    context "with an upload" do
      let(:event_type) { "Integrations::Twitch::UploadPublished" }
      let(:event) { create(:twitch_upload_published_event, watch:) }
      let(:role_column) { :uploads_role_id }

      it "says uploaded" do
        expect(subject_line).to eq("<@&4242> shrkbot_dev uploaded a video: Fragpunk early access, best rounds")
      end
    end
  end

  describe "#fallback" do
    it "ends with the video link" do
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
    let(:eyebrow) { Bot::Discord::Components.text("-# shrkbot_dev · New highlight on Twitch") }
    let(:heading) { Bot::Discord::Components.text("## Fragpunk early access, best rounds") }
    let(:details) { Bot::Discord::Components.text("About 2 h 36 min") }
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

    context "with an upload" do
      let(:event_type) { "Integrations::Twitch::UploadPublished" }
      let(:event) { create(:twitch_upload_published_event, watch:) }
      let(:role_column) { :uploads_role_id }
      let(:eyebrow) { Bot::Discord::Components.text("-# shrkbot_dev · New upload on Twitch") }

      it "names the upload in the eyebrow" do
        expect(container[:components].first[:components].first).to eq(eyebrow)
      end
    end

    context "when the watch has no profile picture" do
      let(:profile_image) { nil }

      it "puts the texts straight into the container" do
        expect(container[:components]).to eq([eyebrow, heading, details, image])
      end
    end

    it "links the video" do
      expect(action_row[:components]).to eq(
        [Bot::Discord::Components.link_button(url: event.url, label: "Watch on Twitch")]
      )
    end
  end
end
