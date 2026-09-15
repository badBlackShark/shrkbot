# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe TwilightStruggle::SequenceGapJob do
  subject(:perform) { described_class.perform_now(external_id) }

  let(:external_id) { "48310" }

  let(:rest_token) { "Bot test-token" }

  before do
    allow(Bot::Config).to receive_messages(owner_id: "999", rest_token:)
    allow(Discordrb::API::User).to receive(:create_pm).with(rest_token, "999").and_return({id: 77}.to_json)
    allow(Bot::Discord::Components).to receive(:create_message)
  end

  context "when the sequence still has a gap" do
    let!(:previous) { create(:twilight_struggle_game, external_id: "48305") }

    it "DMs the owner naming every missing id" do
      perform

      expect(Bot::Discord::Components).to have_received(:create_message).with(
        channel_id: 77,
        content: "shrkbot never received Twilight Struggle games 48306, 48307, 48308, 48309. Re-post them from the site.",
        allowed_mentions: {parse: []}
      )
    end

    context "when only one id is missing" do
      let(:external_id) { "48307" }

      it "uses the singular form" do
        perform

        expect(Bot::Discord::Components).to have_received(:create_message).with(
          channel_id: 77,
          content: "shrkbot never received Twilight Struggle game 48306. Re-post it from the site.",
          allowed_mentions: {parse: []}
        )
      end
    end
  end

  context "when the gap closed between enqueue and run" do
    let!(:previous) { create(:twilight_struggle_game, external_id: "48309") }

    it "sends no message" do
      perform

      expect(Bot::Discord::Components).not_to have_received(:create_message)
    end
  end

  context "when the owner id is blank" do
    let!(:previous) { create(:twilight_struggle_game, external_id: "48305") }

    before { allow(Bot::Config).to receive(:owner_id).and_return("") }

    it "sends no message" do
      perform

      expect(Discordrb::API::User).not_to have_received(:create_pm)
      expect(Bot::Discord::Components).not_to have_received(:create_message)
    end
  end

  context "when more than 20 ids are missing" do
    let!(:previous) { create(:twilight_struggle_game, external_id: "1") }
    let(:external_id) { "30" }

    it "summarizes with the count and the outer ids instead of listing all of them" do
      perform

      expect(Bot::Discord::Components).to have_received(:create_message).with(
        channel_id: 77,
        content: "shrkbot never received 28 Twilight Struggle games, 2 to 29. Re-post them from the site.",
        allowed_mentions: {parse: []}
      )
    end
  end
end
