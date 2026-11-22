# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::CardOwnership do
  include_context "with a stream moving between followed categories"

  describe ".handed_off_post" do
    subject(:handed_off) { described_class.handed_off_post(subscription: follow_b, event:) }

    let(:event) { updated_to_b }

    it { is_expected.to eq(card_of_a) }

    context "when the other follow posts to another channel" do
      let(:channel_b) { 666_000 }

      it { is_expected.to be_nil }
    end

    context "when the card belongs to another server" do
      before do
        follow_a.update!(server_configuration: create(:server_configuration))
      end

      it { is_expected.to be_nil }
    end

    context "when the follow that holds the card still accepts the stream" do
      let(:event) { create(:twitch_stream_updated_event, watch: stream_watch, session:, category_id: "cat-a", occurred_at: 1.minute.from_now) }

      it { is_expected.to be_nil }
    end

    context "when the holder has no message" do
      before do
        card_of_a.update!(message_id: nil)
      end

      it { is_expected.to be_nil }
    end
  end

  describe ".successor" do
    subject(:successor) { described_class.successor(post: card_of_a, event: updated_to_b) }

    it { is_expected.to eq(follow_b) }

    context "when the other follow posts to another channel" do
      let(:channel_b) { 666_000 }

      it { is_expected.to be_nil }
    end

    context "when the other follow has a channel of its own for live posts" do
      before do
        follow_b.subscribed_events.update_all(channel_id: 555_000)
        follow_b.update!(channel_id: 666_000)
      end

      it { is_expected.to eq(follow_b) }
    end

    context "when the other follow already holds a message for the story" do
      before do
        create(:feed_post, :sent, subscription: follow_b, story_key:)
      end

      it { is_expected.to be_nil }
    end

    context "when the other follow only has an empty row for the story" do
      before do
        create(:feed_post, subscription: follow_b, story_key:)
      end

      it { is_expected.to eq(follow_b) }
    end

    context "when the stream is below the other follow's floor" do
      before do
        follow_b.settings.update!(min_viewers: 100)
      end

      it { is_expected.to be_nil }
    end

    context "when the other follow does not demand live posts" do
      before do
        follow_b.subscribed_events.delete_all
      end

      it { is_expected.to be_nil }
    end

    context "when a direct follow of the channel takes the stream in" do
      let!(:direct) { create(:feed_subscription, :active, server_configuration:, watch: stream_watch, channel_id: 555_000) }

      before do
        direct.settings.update!(categories: [{"id" => "cat-b", "name" => "Elsewhere"}])
        create(:feed_subscribed_event, subscription: direct, event_type: "Integrations::Twitch::StreamStarted", subscribed_since: 1.day.ago)
      end

      it "is chosen, since the category follow defers to it" do
        expect(successor).to eq(direct)
      end
    end

    context "when the follow of another server takes the stream in" do
      before do
        follow_b.update!(server_configuration: create(:server_configuration))
      end

      it { is_expected.to be_nil }
    end
  end
end
