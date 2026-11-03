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

  it "edits the post's own message with the event's card and no mentions" do
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
      Integrations::Twitch::StreamEnded.create!(
        watch:,
        subject_key: "stream-end:#{session}",
        occurred_at: 1.minute.from_now,
        session:,
        login: "shrkbot_dev",
        display_name: "shrkbot_dev",
        story_key: "stream:#{session}"
      )
    end

    it "edits nothing" do
      result

      expect(Bot::Discord::Components).not_to have_received(:edit)
    end
  end

  context "when a human deleted the message" do
    before do
      allow(Bot::Discord::Components).to receive(:edit).and_raise(Discordrb::Errors::UnknownMessage.new("Unknown Message"))
    end

    it "forgets the message id and does not raise" do
      expect { result }.to change { post.reload.message_id }.from(777_000).to(nil)
    end
  end
end
