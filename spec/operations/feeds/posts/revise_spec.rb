# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Ops::Feeds::Posts::Revise do
  subject(:result) { described_class.call(post:, event:) }

  let(:watch) { create(:integration_watch, :twitch) }
  let(:subscription) { create(:feed_subscription, :twitch, :active, watch:, channel_id: 555_000) }
  let(:session) { "40000000001" }
  let!(:started) { create(:twitch_stream_started_event, watch:, session:, occurred_at: 20.minutes.ago) }
  let!(:sampled) { create(:twitch_stream_sampled_event, watch:, session:, occurred_at: Time.current) }
  let(:event) { sampled }
  let!(:post) { create(:feed_post, :sent, subscription:, story_key: "stream:#{session}", channel_id: 555_000, message_id: 777_000) }
  let(:card) { Feeds::Twitch::Announcement.new(event:, subscription:, image_url: "https://box.art/x.jpg").card }

  before do
    subscription.settings.update!(live_role_id: 4242)
    allow(Feeds::Twitch::LiveImage).to receive(:for).and_return("https://box.art/x.jpg")
    allow(Bot::Discord::Components).to receive(:edit)
  end

  it "edits the post's own message with the event's card" do
    result

    expect(Bot::Discord::Components).to have_received(:edit).with(channel_id: 555_000, message_id: 777_000, rendered: card)
  end

  context "with a custom message for live posts" do
    before do
      create(:feed_subscribed_event, subscription:, event_type: "Integrations::Twitch::StreamStarted", template: "{streamer} ist live!")
    end

    it "keeps the live role and the custom message on the refreshed card" do
      result

      expect(Bot::Discord::Components).to have_received(:edit) do |rendered:, **|
        expect(rendered[:components].first).to eq(Bot::Discord::Components.text("<@&4242> shrkbot_dev ist live!"))
      end
    end
  end

  context "when a newer event of the story exists" do
    let(:event) { started }

    it "edits nothing, so a retried older refresh cannot overwrite it" do
      result

      expect(Bot::Discord::Components).not_to have_received(:edit)
    end
  end

  context "when the stream ended after the event" do
    before do
      create(:twitch_stream_ended_event, watch:, session:, occurred_at: 1.minute.from_now)
    end

    it "edits nothing" do
      result

      expect(Bot::Discord::Components).not_to have_received(:edit)
    end
  end

  context "when the event is the end of the stream" do
    let!(:ended) { create(:twitch_stream_ended_event, watch:, session:, occurred_at: 1.minute.from_now) }
    let(:event) { ended }
    let(:vod_url) { "https://www.twitch.tv/videos/1" }
    let(:ended_card) do
      Feeds::Twitch::EndedAnnouncement.new(event: ended, subscription:, history: Feeds::Twitch::TitleHistory.for(ended), vod_url:).card
    end

    before do
      allow(Feeds::Twitch::Vod).to receive(:url_for).with(ended).and_return(vod_url)
    end

    it "edits the message into the ended card" do
      result

      expect(Bot::Discord::Components).to have_received(:edit).with(channel_id: 555_000, message_id: 777_000, rendered: ended_card)
    end

    context "when the subscription deletes ended cards" do
      before do
        subscription.settings.update!(live_end_mode: "delete")
        allow(Bot::Discord::Components).to receive(:delete_message)
      end

      it "deletes the message and forgets its id" do
        expect { result }.to change { post.reload.message_id }.from(777_000).to(nil)
        expect(Bot::Discord::Components).to have_received(:delete_message).with(555_000, 777_000)
        expect(Bot::Discord::Components).not_to have_received(:edit)
      end

      it "records that shrkbot deleted it" do
        expect { result }.to change { post.reload.retracted_at }.from(nil)
      end

      context "when the message is already gone" do
        before do
          allow(Bot::Discord::Components).to receive(:delete_message).and_raise(Discordrb::Errors::UnknownMessage.new("Unknown Message"))
        end

        it "forgets the message id and does not raise" do
          expect { result }.to change { post.reload.message_id }.to(nil)
        end
      end
    end
  end

  context "with a category filter" do
    let(:switched_away) { "summary" }
    let(:category_id) { "B" }
    let!(:sampled) { create(:twitch_stream_sampled_event, watch:, session:, occurred_at: Time.current, category_id:, category_name: "Elsewhere") }
    let(:switched_card) { Feeds::Twitch::SwitchedAnnouncement.new(event:, subscription:).card }

    before do
      subscription.settings.update!(categories: [{"id" => "A", "name" => "A"}], switched_away:)
      create(:feed_subscribed_event, subscription:, event_type: "Integrations::Twitch::StreamStarted", subscribed_since: 1.day.ago)
      allow(Bot::Discord::Components).to receive(:delete_message)
      allow(Bot::Discord::Components).to receive(:create_with_subject).and_return(888_000)
    end

    context "when the stream switched away and the summary is wanted" do
      it "edits the message into the summary card and keeps it" do
        expect { result }.not_to change { post.reload.message_id }
        expect(Bot::Discord::Components).to have_received(:edit).with(channel_id: 555_000, message_id: 777_000, rendered: switched_card)
      end
    end

    context "when the stream switched away and deletion is wanted" do
      let(:switched_away) { "delete" }

      it "deletes the message and remembers it did" do
        result

        expect(Bot::Discord::Components).to have_received(:delete_message).with(555_000, 777_000)
        expect(post.reload).to have_attributes(message_id: nil, retracted_at: be_present)
      end
    end

    context "when the stream is back in a chosen category after shrkbot deleted the post" do
      let(:category_id) { "A" }
      let(:live_card) { Feeds::Twitch::Announcement.new(event:, subscription:, image_url: "https://box.art/x.jpg").card }

      before do
        post.update!(message_id: nil, retracted_at: 1.minute.ago)
      end

      it "posts the live card again without a ping and stores the new message" do
        result

        expect(Bot::Discord::Components).to have_received(:create_with_subject).with(
          hash_including(channel_id: 555_000, rendered: live_card, allowed_mentions: {parse: []})
        )
        expect(post.reload).to have_attributes(channel_id: 555_000, message_id: 888_000, retracted_at: nil)
      end

      context "when the server no longer follows Live" do
        before do
          subscription.subscribed_events.delete_all
        end

        it "does not post it again" do
          result

          expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
        end
      end

      context "when the channel is gone" do
        before do
          allow(Bot::Discord::Components).to receive(:create_with_subject).and_raise(Discordrb::Errors::UnknownChannel.new("gone"))
        end

        it "gives the post up instead of retrying it on every sample" do
          result

          expect(post.reload).to have_attributes(message_id: nil, retracted_at: nil)
        end
      end
    end

    context "when the stream is back in a chosen category but the message was lost, not retracted" do
      let(:category_id) { "A" }

      before do
        post.update!(message_id: nil)
      end

      it "sends nothing" do
        result

        expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
        expect(Bot::Discord::Components).not_to have_received(:edit)
      end
    end

    context "when the stream ended while the post was retracted" do
      let!(:ended) { create(:twitch_stream_ended_event, watch:, session:, occurred_at: 1.minute.from_now, category_id: "A") }
      let(:event) { ended }

      before do
        subscription.settings.update!(live_end_mode: "mark_ended")
        post.update!(message_id: nil, retracted_at: 1.minute.ago)
      end

      it "sends and edits nothing" do
        result

        expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
        expect(Bot::Discord::Components).not_to have_received(:edit)
      end
    end
  end

  context "when the message can no longer be edited" do
    let(:error) { Discordrb::Errors::UnknownMessage.new("Unknown Message") }

    before do
      allow(Bot::Discord::Components).to receive(:edit).and_raise(error)
    end

    it "forgets the message id and does not raise" do
      expect { result }.to change { post.reload.message_id }.from(777_000).to(nil)
    end

    context "because the channel is gone" do
      let(:error) { Discordrb::Errors::UnknownChannel.new("Unknown Channel") }

      it "forgets the message id" do
        expect { result }.to change { post.reload.message_id }.to(nil)
      end
    end

    context "because the bot lost its permission" do
      let(:error) { Discordrb::Errors::NoPermission.new("Missing Permissions") }

      it "forgets the message id" do
        expect { result }.to change { post.reload.message_id }.to(nil)
      end
    end
  end

  context "when an earlier revision already forgot the message" do
    before do
      post.update!(message_id: nil)
    end

    it "edits nothing" do
      result

      expect(Bot::Discord::Components).not_to have_received(:edit)
    end
  end
end
