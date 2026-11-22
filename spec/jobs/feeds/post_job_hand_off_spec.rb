# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Feeds::PostJob, "handing a live card over" do
  subject(:perform) { described_class.perform_now(follow_b, updated_to_b) }

  include_context "with a stream moving between followed categories"

  let(:new_card) { Feeds::TwitchCategory.announcement(event: updated_to_b, subscription: follow_b).card }

  it "edits the card of the follow the stream left instead of posting a second one" do
    perform

    expect(Bot::Discord::Components).to have_received(:edit).with(channel_id: 555_000, message_id: 777_000, rendered: new_card)
    expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
    expect(follow_b.posts.pluck(:message_id)).to eq([777_000])
  end

  context "when the follow the stream left posts to another channel" do
    let(:channel_b) { 666_000 }

    it "posts a card of its own" do
      perform

      expect(Bot::Discord::Components).to have_received(:create_with_subject).with(hash_including(channel_id: 666_000))
      expect(Bot::Discord::Components).not_to have_received(:edit)
      expect(card_of_a.reload.message_id).to eq(777_000)
    end
  end

  context "when the card of the follow the stream left was deleted" do
    before do
      allow(Bot::Discord::Components).to receive(:edit).and_raise(Discordrb::Errors::UnknownMessage.new("Unknown Message"))
    end

    it "posts a card of its own instead of leaving the stream without one" do
      perform

      expect(Bot::Discord::Components).to have_received(:create_with_subject).once
      expect(follow_b.posts.pluck(:message_id)).to eq([888_000])
      expect(card_of_a.reload.message_id).to be_nil
    end
  end

  context "when the follow already has a row for the story" do
    before do
      create(:feed_post, subscription: follow_b, story_key:)
    end

    it "posts nothing, so one follow never pings twice in a session" do
      perform

      expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
      expect(Bot::Discord::Components).not_to have_received(:edit)
    end
  end
end
