# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Ops::Feeds::Posts::Create do
  subject(:result) { described_class.call(subscription:, event:) }

  let(:watch) { create(:integration_watch, name: "Team Fortress 2") }
  let(:role_id) { 4242 }
  let(:subscription) { create(:feed_subscription, watch:, channel_id: 555_000, role_id:) }
  let(:event) { create(:steam_news_event, watch:, title: "Smissmas 2026", story_key: "story-1") }
  let(:announcement) { Feeds::Announcement.new(event:, subscription:) }

  before do
    create(:feed_subscribed_event, subscription:, event_type: event.type)
    allow(Bot::Discord::Components).to receive_messages(create_message: 777_000, convert_to_v2: nil)
  end

  it "sends the subject first, allowing only the subscription's role to ping" do
    result

    expect(Bot::Discord::Components).to have_received(:create_message).with(
      channel_id: 555_000,
      content: "<@&4242> New Team Fortress 2 patch notes: Smissmas 2026",
      allowed_mentions: {parse: [], roles: [4242]}
    )
  end

  it "converts the message into the card and leaves the edit on the suppressed default mentions" do
    result

    expect(Bot::Discord::Components).to have_received(:convert_to_v2).with(555_000, 777_000, announcement.card)
  end

  it "records which message the story became" do
    expect { result }.to change { subscription.posts.count }.by(1)

    expect(subscription.posts.sole).to have_attributes(
      story_key: "story-1",
      event_id: event.id,
      discord_channel_id: 555_000,
      discord_message_id: 777_000
    )
  end

  context "without a role" do
    let(:role_id) { nil }

    it "allows no mention at all" do
      result

      expect(Bot::Discord::Components).to have_received(:create_message).with(
        channel_id: 555_000,
        content: "New Team Fortress 2 patch notes: Smissmas 2026",
        allowed_mentions: {parse: []}
      )
    end
  end

  context "when sending fails" do
    before do
      allow(Bot::Discord::Components).to receive(:create_message).and_raise(Discordrb::Errors::NoPermission)
    end

    it "records nothing" do
      expect { result }.to raise_error(Discordrb::Errors::NoPermission)
      expect(subscription.posts).to be_empty
    end
  end
end
