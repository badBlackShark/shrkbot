# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe TwilightStruggle::TaggableReport do
  subject(:taggable) { described_class.new(report, 555).report }

  let(:usa) { TwilightStruggle::Player.new(name: "Alice", country_code: "US", discord_id: "111") }
  let(:ussr) { TwilightStruggle::Player.new(name: "Bob", country_code: "RU", discord_id: ussr_discord_id) }
  let(:ussr_discord_id) { "222" }
  let(:members) { ["111", "222"] }
  let(:report) do
    TwilightStruggle::GameReport.new(
      usa:,
      ussr:,
      winning_side: "usa",
      winning_turn: 6,
      winning_method: "defcon",
      game_code: "R1",
      game_date: "2026-07-20"
    )
  end

  before do
    allow(Bot::Discord::GuildMembership).to receive(:user_member?) { |_guild, user_id| members.include?(user_id) }
  end

  context "when both players are on the server" do
    it "keeps both Discord IDs" do
      expect([taggable.usa.discord_id, taggable.ussr.discord_id]).to eq(["111", "222"])
    end
  end

  context "when a player is not on the server" do
    let(:members) { ["111"] }

    it "drops only that player's Discord ID" do
      expect([taggable.usa.discord_id, taggable.ussr.discord_id]).to eq(["111", nil])
    end
  end

  context "when a player has no Discord ID" do
    let(:ussr_discord_id) { nil }

    before do
      taggable
    end

    it "looks up only the player who has one" do
      expect(Bot::Discord::GuildMembership).to have_received(:user_member?).once.with(555, "111")
    end
  end
end
