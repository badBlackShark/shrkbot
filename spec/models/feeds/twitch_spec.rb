# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch do
  let(:subscription) { create(:feed_subscription, :twitch) }

  describe ".role_id_for" do
    subject(:role_id) { described_class.role_id_for(subscription, "Integrations::Twitch::StreamStarted") }

    before { subscription.settings.update!(live_role_id: 4242) }

    it "is the live role in the subscription's settings" do
      expect(role_id).to eq(4242)
    end
  end

  describe ".event_types" do
    it "lists live first, then the media types" do
      expect(described_class.event_types).to eq(
        %w[
          Integrations::Twitch::StreamStarted
          Integrations::Twitch::HighlightPublished
          Integrations::Twitch::UploadPublished
          Integrations::Twitch::FeaturedClipPublished
          Integrations::Twitch::ClipCreated
        ]
      )
    end
  end

  describe ".default_event_types" do
    it "is Live and Highlights" do
      expect(described_class.default_event_types).to eq(
        %w[Integrations::Twitch::StreamStarted Integrations::Twitch::HighlightPublished]
      )
    end
  end

  describe ".template_tokens" do
    it "adds the title and the clipper" do
      expect(described_class.template_tokens).to eq(%w[streamer category title clipper])
    end
  end

  describe ".announcement" do
    subject(:announcement) { described_class.announcement(event:, subscription:) }

    context "with a live event" do
      let(:event) { create(:twitch_stream_started_event, watch: subscription.watch) }

      before do
        allow(Feeds::Twitch::LiveImage).to receive(:for).with(event).and_return(nil)
      end

      it { is_expected.to be_a(Feeds::Twitch::Announcement) }
    end

    context "with a video event" do
      let(:event) { create(:twitch_highlight_published_event, watch: subscription.watch) }

      it { is_expected.to be_a(Feeds::Twitch::VideoAnnouncement) }
    end

    context "with a clip event" do
      let(:event) { create(:twitch_clip_created_event, watch: subscription.watch) }

      before do
        allow(Feeds::Twitch::GameLookup).to receive(:find).with("18122").and_return(nil)
      end

      it { is_expected.to be_a(Feeds::Twitch::ClipAnnouncement) }
    end

    context "with an ended stream" do
      let(:event) { create(:twitch_stream_ended_event, watch: subscription.watch) }

      before do
        allow(Feeds::Twitch::Ending).to receive(:announcement).with(event:, subscription:).and_return(:ending)
      end

      it { is_expected.to eq(:ending) }
    end
  end

  describe ".accepts?" do
    subject(:accepted) { described_class.accepts?(subscription, instance_double(Integrations::Twitch::StreamStarted)) }

    it { is_expected.to be(true) }
  end

  describe ".retract?" do
    subject(:retract) { described_class.retract?(subscription, event) }

    let(:event) { build(:twitch_stream_ended_event) }

    before { subscription.settings.update!(live_end_mode:) }

    context "with an ended stream in delete mode" do
      let(:live_end_mode) { "delete" }

      it { is_expected.to be(true) }
    end

    context "with an ended stream in another mode" do
      let(:live_end_mode) { "keep" }

      it { is_expected.to be(false) }
    end

    context "with a live event in delete mode" do
      let(:live_end_mode) { "delete" }
      let(:event) { build(:twitch_stream_updated_event) }

      it { is_expected.to be(false) }
    end
  end
end
