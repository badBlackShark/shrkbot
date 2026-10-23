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
    allow(Bot::Discord::Components).to receive_messages(create_message: 777_000, convert_to_v2: true, edit_content: nil)
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

  it "records that the story was posted" do
    expect { result }.to change { subscription.posts.count }.by(1)

    expect(subscription.posts.sole.story_key).to eq("story-1")
  end

  it "leaves the converted message alone" do
    result

    expect(Bot::Discord::Components).not_to have_received(:edit_content)
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

  context "when the story was already claimed" do
    before do
      create(:feed_post, subscription:, story_key: "story-1")
    end

    it "raises and sends nothing" do
      expect { result }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Bot::Discord::Components).not_to have_received(:create_message)
    end
  end

  context "when sending fails" do
    before do
      allow(Bot::Discord::Components).to receive(:create_message).and_raise(Discordrb::Errors::NoPermission)
    end

    it "releases the claim and re-raises so the send can be retried" do
      expect { result }.to raise_error(Discordrb::Errors::NoPermission)
      expect(Feeds::Post.count).to eq(0)
    end
  end

  context "when the conversion fails" do
    before do
      allow(Bot::Discord::Components).to receive(:convert_to_v2).and_return(false)
    end

    it "puts the link on the plain message" do
      result

      expect(Bot::Discord::Components).to have_received(:edit_content).with(555_000, 777_000, announcement.fallback)
    end

    it "keeps the claim" do
      expect { result }.to change { subscription.posts.count }.by(1)
    end
  end
end
