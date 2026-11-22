# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Ops::Feeds::Posts::Revise, "handing a live card over" do
  subject(:result) { described_class.call(post: card_of_a, event:) }

  include_context "with a stream moving between followed categories"

  let(:event) { updated_to_b }
  let(:new_card) { Feeds::TwitchCategory.announcement(event: updated_to_b, subscription: follow_b).card }

  context "when another follow of the server takes the stream in, posting to the same channel" do
    it "edits the card with the new owner's settings instead of writing the switched-away summary" do
      result

      expect(Bot::Discord::Components).to have_received(:edit).once.with(channel_id: 555_000, message_id: 777_000, rendered: new_card)
      expect(follow_b.posts.pluck(:message_id)).to eq([777_000])
      expect(card_of_a.reload).to have_attributes(message_id: nil, retracted_at: nil)
    end

    it "deletes nothing and pings nobody, even when the old follow deletes on switching away" do
      follow_a.settings.update!(switched_away: "delete")

      result

      expect(Bot::Discord::Components).not_to have_received(:delete_message)
      expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
    end
  end

  context "when the follow that takes the stream in posts to another channel" do
    let(:channel_b) { 666_000 }
    let(:switched_card) { Feeds::Twitch::SwitchedAnnouncement.new(event:, subscription: follow_a).card }

    it "settles the old card as usual and leaves the other follow to post" do
      result

      expect(Bot::Discord::Components).to have_received(:edit).once.with(channel_id: 555_000, message_id: 777_000, rendered: switched_card)
      expect(card_of_a.reload.message_id).to eq(777_000)
      expect(follow_b.posts).to be_empty
    end
  end

  context "when nobody takes the stream in" do
    before do
      follow_b.destroy!
    end

    it "settles the old card as usual" do
      result

      expect(Bot::Discord::Components).to have_received(:edit).once
      expect(card_of_a.reload.message_id).to eq(777_000)
    end
  end

  context "when the stream ended" do
    let!(:ended) { create(:twitch_stream_ended_event, watch: stream_watch, session:, category_id: "cat-b", occurred_at: 1.minute.from_now) }
    let(:event) { ended }

    before do
      follow_a.settings.update!(live_end_mode: "mark_ended")
    end

    it "ends the card of the follow that holds it and hands nothing over" do
      result

      expect(Bot::Discord::Components).to have_received(:edit).once.with(hash_including(channel_id: 555_000, message_id: 777_000))
      expect(card_of_a.reload.message_id).to eq(777_000)
      expect(follow_b.posts).to be_empty
    end
  end

  context "when the stream returns to the first category" do
    let(:back_in_a) { create(:twitch_stream_updated_event, watch: stream_watch, session:, category_id: "cat-a", occurred_at: 1.minute.from_now) }
    let(:card_of_b) { follow_b.posts.find_by!(story_key:) }

    before do
      described_class.call(post: card_of_a, event: updated_to_b)
    end

    it "moves the card back by an edit, without a second ping for the first follow" do
      described_class.call(post: card_of_b, event: back_in_a)

      expect(Bot::Discord::Components).to have_received(:edit).twice
      expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
      expect(card_of_a.reload.message_id).to eq(777_000)
      expect(card_of_b.reload.message_id).to be_nil
    end

    it "does not post for the first follow when the announcement for the return arrives" do
      Feeds::PostJob.perform_now(follow_a, back_in_a)

      expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
    end
  end
end
