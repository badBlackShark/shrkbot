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

    it "enqueues a delete job with the stored channel and message ids" do
      expect { result }.to have_enqueued_job(TwilightStruggle::DeleteMessageJob).with(111, 222)
    end

    it "still destroys the row" do
      result
      expect(TwilightStruggle::Game.find_by(id: game.id)).to be_nil
    end
  end

  context "when the game has no posted message" do
    let!(:game) { create(:twilight_struggle_game, discord_channel_id: nil, discord_message_id: nil) }

    it "does not enqueue a delete job" do
      expect { result }.not_to have_enqueued_job(TwilightStruggle::DeleteMessageJob)
    end

    it "still destroys the row" do
      result
      expect(TwilightStruggle::Game.find_by(id: game.id)).to be_nil
    end
  end
end
