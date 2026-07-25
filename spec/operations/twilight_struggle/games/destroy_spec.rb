# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::TwilightStruggle::Games::Destroy do
  subject(:result) { described_class.call(game:) }

  let!(:game) { create(:twilight_struggle_game) }

  it "destroys the row" do
    result
    expect(TwilightStruggle::Game.find_by(id: game.id)).to be_nil
  end

  it "returns success" do
    expect(result).to be_success
  end

  context "when the game has a posted message" do
    let!(:game) { create(:twilight_struggle_game, discord_channel_id: "111", discord_message_id: "222") }

    before do
      allow(Bot::Discord::MessageApi).to receive(:delete)
    end

    it "deletes the message at the stored channel and message ids" do
      result
      expect(Bot::Discord::MessageApi).to have_received(:delete).with(channel_id: 111, message_id: 222)
    end

    it "still destroys the row" do
      result
      expect(TwilightStruggle::Game.find_by(id: game.id)).to be_nil
    end
  end

  context "when the game has no posted message" do
    let!(:game) { create(:twilight_struggle_game, discord_channel_id: nil, discord_message_id: nil) }

    before do
      allow(Bot::Discord::MessageApi).to receive(:delete)
    end

    it "does not call delete" do
      result
      expect(Bot::Discord::MessageApi).not_to have_received(:delete)
    end

    it "still destroys the row" do
      result
      expect(TwilightStruggle::Game.find_by(id: game.id)).to be_nil
    end
  end

  context "when delete raises an error" do
    let!(:game) { create(:twilight_struggle_game, discord_channel_id: "111", discord_message_id: "222") }

    before do
      allow(Bot::Discord::MessageApi).to receive(:delete).and_raise(Bot::Discord::MessageApi::Error.new("boom", status: 500))
      allow(Rails.logger).to receive(:warn)
    end

    it "still destroys the row" do
      result
      expect(TwilightStruggle::Game.find_by(id: game.id)).to be_nil
    end

    it "still returns success" do
      expect(result).to be_success
    end

    it "logs a warning" do
      result
      expect(Rails.logger).to have_received(:warn).with(/\[TwilightStruggle\] message 222 not deleted: Bot::Discord::MessageApi::Error: boom/)
    end
  end
end
