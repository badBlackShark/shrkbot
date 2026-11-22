# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Ops::Feeds::Posts::HandOff do
  subject(:result) { described_class.call(post: card_of_a, subscription: follow_b, event: updated_to_b) }

  include_context "with a stream moving between followed categories"

  let(:new_card) { Feeds::TwitchCategory.announcement(event: updated_to_b, subscription: follow_b).card }

  it "edits the message with the new owner's card and pings nobody" do
    result

    expect(Bot::Discord::Components).to have_received(:edit).with(channel_id: 555_000, message_id: 777_000, rendered: new_card)
    expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
  end

  it "gives the message to a row of the new owner" do
    expect(result.value).to have_attributes(subscription: follow_b, channel_id: 555_000, message_id: 777_000, retracted_at: nil)
  end

  it "keeps the old owner's row as its marker, without the message and without a retraction" do
    result

    expect(card_of_a.reload).to have_attributes(message_id: nil, retracted_at: nil)
  end

  context "when the new owner has an empty row from an earlier turn" do
    let!(:empty_row) { create(:feed_post, subscription: follow_b, story_key:) }

    it "fills that row instead of adding one" do
      expect { result }.not_to change(Feeds::Post, :count)
      expect(empty_row.reload.message_id).to eq(777_000)
    end
  end

  context "when the new owner already holds the message" do
    before do
      create(:feed_post, :sent, subscription: follow_b, story_key:)
    end

    it "changes nothing" do
      result

      expect(Bot::Discord::Components).not_to have_received(:edit)
      expect(card_of_a.reload.message_id).to eq(777_000)
    end
  end

  context "when someone else already took the message from the post" do
    before do
      Feeds::Post.find(card_of_a.id).update!(message_id: nil)
    end

    it "edits nothing" do
      result

      expect(Bot::Discord::Components).not_to have_received(:edit)
      expect(follow_b.posts).to be_empty
    end
  end

  context "when a moderator deleted the message" do
    before do
      allow(Bot::Discord::Components).to receive(:edit).and_raise(Discordrb::Errors::UnknownMessage.new("Unknown Message"))
    end

    it "forgets the message so the new owner can post normally" do
      expect(result).to be_success
      expect(card_of_a.reload.message_id).to be_nil
      expect(follow_b.posts).to be_empty
    end
  end

  context "when the bot lost its permission" do
    before do
      allow(Bot::Discord::Components).to receive(:edit).and_raise(Discordrb::Errors::NoPermission.new("Missing Permissions"))
    end

    it "tells the server and forgets the message" do
      expect { result }.to change(Notification.where(kind: "feed_post_failed"), :count).by(1)
      expect(card_of_a.reload.message_id).to be_nil
    end
  end
end
