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

  describe ".template_tokens" do
    it "adds the title and the clipper" do
      expect(described_class.template_tokens).to eq(%w[streamer category title clipper])
    end
  end

  describe ".tokens_for" do
    {
      "Integrations::Twitch::StreamStarted" => %w[streamer category title],
      "Integrations::Twitch::HighlightPublished" => %w[streamer title],
      "Integrations::Twitch::UploadPublished" => %w[streamer title],
      "Integrations::Twitch::FeaturedClipPublished" => %w[streamer category title clipper],
      "Integrations::Twitch::ClipCreated" => %w[streamer category title clipper]
    }.each do |event_type, tokens|
      it "is #{tokens.join(", ")} for #{event_type.demodulize}" do
        expect(described_class.tokens_for(event_type)).to eq(tokens)
      end
    end
  end

  describe ".notification_tokens" do
    it "is the template tokens, which already include the title" do
      expect(described_class.notification_tokens).to eq(described_class.template_tokens)
    end
  end

  describe ".default_notification" do
    subject(:default_notification) { described_class.default_notification("Integrations::Twitch::StreamSampled") }

    it "has no default text for an event that is not a post type" do
      expect(default_notification).to be_nil
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

    context "with a live event outside the chosen categories" do
      let(:event) { create(:twitch_stream_updated_event, watch: subscription.watch, category_id: "B") }

      before { subscription.settings.update!(categories: [{"id" => "A", "name" => "A"}]) }

      it { is_expected.to be_a(Feeds::Twitch::SwitchedAnnouncement) }
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

  describe ".post_type" do
    it "counts a category switch as a Live post" do
      expect(described_class.post_type("Integrations::Twitch::StreamUpdated")).to eq("Integrations::Twitch::StreamStarted")
    end

    it "renders revisions of a live post with the Live template and role" do
      expect(described_class.post_type("Integrations::Twitch::StreamSampled")).to eq("Integrations::Twitch::StreamStarted")
    end

    it "leaves every other type as it is" do
      expect(described_class.post_type("Integrations::Twitch::ClipCreated")).to eq("Integrations::Twitch::ClipCreated")
    end
  end

  describe ".announced_types" do
    it "leaves out the revision-only events" do
      expect(described_class.announced_types).not_to include("Integrations::Twitch::StreamSampled")
    end
  end

  describe ".accepts?" do
    subject(:accepted) { described_class.accepts?(subscription, event) }

    let(:categories) { [{"id" => "A", "name" => "Alpha"}] }
    let(:event) { build(:twitch_stream_started_event, category_id:) }
    let(:category_id) { "A" }

    before { subscription.settings.update!(categories:) }

    it { is_expected.to be(true) }

    context "when the stream is outside the filter" do
      let(:category_id) { "B" }

      it { is_expected.to be(false) }
    end

    context "when the stream switched into the filter" do
      let(:event) { build(:twitch_stream_updated_event, category_id:) }

      it { is_expected.to be(true) }
    end

    context "when a clip is inside the filter" do
      let(:event) { build(:twitch_clip_created_event, category_id:) }

      it { is_expected.to be(true) }
    end

    context "when a clip is outside the filter" do
      let(:event) { build(:twitch_clip_created_event, category_id: "B") }

      it { is_expected.to be(false) }
    end

    context "when the event is a video" do
      let(:event) { build(:twitch_highlight_published_event) }

      it { is_expected.to be(true) }
    end

    context "when the filter is empty" do
      let(:categories) { [] }
      let(:category_id) { "B" }

      it { is_expected.to be(true) }
    end
  end

  describe ".retract?" do
    subject(:retract) { described_class.retract?(subscription, event) }

    let(:event) { build(:twitch_stream_ended_event) }

    before { subscription.settings.update!(live_end_mode:, switched_away:, categories:) }

    let(:live_end_mode) { "mark_ended" }
    let(:switched_away) { "summary" }
    let(:categories) { [] }

    context "with an ended stream in delete mode" do
      let(:live_end_mode) { "delete" }

      it { is_expected.to be(true) }
    end

    context "with an ended stream in another mode" do
      let(:live_end_mode) { "keep" }

      it { is_expected.to be(false) }
    end

    context "with an accepted live event in delete mode" do
      let(:live_end_mode) { "delete" }
      let(:switched_away) { "delete" }
      let(:event) { build(:twitch_stream_updated_event) }

      it { is_expected.to be(false) }
    end

    context "with a switched-away event" do
      let(:categories) { [{"id" => "A", "name" => "A"}] }
      let(:event) { build(:twitch_stream_updated_event, category_id: "B") }

      it { is_expected.to be(false) }

      context "when switching away deletes" do
        let(:switched_away) { "delete" }

        it { is_expected.to be(true) }
      end
    end
  end

  describe ".revive?" do
    subject(:revive) { described_class.revive?(subscription, event) }

    let(:categories) { [{"id" => "A", "name" => "A"}] }
    let(:event) { build(:twitch_stream_updated_event, category_id:) }
    let(:category_id) { "A" }

    before { subscription.settings.update!(categories:) }

    it { is_expected.to be(true) }

    context "when the stream is outside the filter" do
      let(:category_id) { "B" }

      it { is_expected.to be(false) }
    end

    context "when the stream ended" do
      let(:event) { build(:twitch_stream_ended_event, category_id:) }

      it { is_expected.to be(false) }
    end
  end
end
