# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::TwilightStruggle::Games::Post do
  subject(:result) { described_class.call(game:, report:) }

  def body_text(body)
    body[:components].first[:components].map { |block| block[:content] }.join
  end

  let(:usa) { TwilightStruggle::Player.new(name: "Alice", flag: "🇺🇸", discord_id: "111") }
  let(:ussr) { TwilightStruggle::Player.new(name: "Bob", flag: "🇷🇺", discord_id: "222") }
  let(:video_urls) { [] }
  let(:report) do
    TwilightStruggle::GameReport.new(
      usa:,
      ussr:,
      winning_side: "usa",
      winning_turn: 6,
      winning_method: "defcon",
      game_code: "R1",
      game_date: "2026-07-20",
      video_urls:
    )
  end

  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:game) { create(:twilight_struggle_game, tournament:) }

  let(:created_messages) { [] }
  let(:edited_messages) { [] }

  before do
    allow(Bot::Discord::MessageApi).to receive(:create) do |channel_id:, body:|
      created_messages << {channel_id:, body:}
      "999"
    end
    allow(Bot::Discord::MessageApi).to receive(:edit) do |channel_id:, message_id:, body:|
      edited_messages << {channel_id:, message_id:, body:}
      nil
    end
  end

  context "when no destination channel is configured anywhere in the chain" do
    it "does not touch the Discord API" do
      result
      expect(Bot::Discord::MessageApi).not_to have_received(:create)
      expect(Bot::Discord::MessageApi).not_to have_received(:edit)
    end

    it "returns success" do
      expect(result).to be_success
    end

    it "leaves discord_message_id nil" do
      result
      expect(game.reload.discord_message_id).to be_nil
    end
  end

  context "when the destination is configured on the tournament itself" do
    let(:tournament) { create(:twilight_struggle_tournament, discord_channel_id: "555") }

    it "creates in that channel" do
      result
      expect(created_messages.first[:channel_id]).to eq(555)
    end

    it "persists the channel and message ids on the game" do
      result
      game.reload
      expect(game.discord_channel_id).to eq(555)
      expect(game.discord_message_id).to eq(999)
    end
  end

  context "when the destination is inherited from the parent tournament" do
    let(:parent_tournament) { create(:twilight_struggle_tournament, discord_channel_id: "777") }
    let(:tournament) { create(:twilight_struggle_tournament, parent: parent_tournament) }

    it "creates in the parent's channel" do
      result
      expect(created_messages.first[:channel_id]).to eq(777)
    end
  end

  context "when the game already has a posted message" do
    let(:tournament) { create(:twilight_struggle_tournament, discord_channel_id: "555") }
    let(:game) { create(:twilight_struggle_game, tournament:, discord_channel_id: "111", discord_message_id: "222") }

    it "edits in place at the game's stored channel id" do
      result
      expect(edited_messages.first[:channel_id]).to eq(111)
      expect(edited_messages.first[:message_id]).to eq(222)
    end

    it "does not call create" do
      result
      expect(Bot::Discord::MessageApi).not_to have_received(:create)
    end

    it "leaves the stored ids unchanged" do
      result
      game.reload
      expect(game.discord_channel_id).to eq(111)
      expect(game.discord_message_id).to eq(222)
    end

    context "when the tournament's configured channel has since changed" do
      it "still edits the old stored channel, not the currently configured one" do
        result
        expect(edited_messages.first[:channel_id]).to eq(111)
      end
    end

    context "when edit raises a 404 (message deleted by a human)" do
      before do
        allow(Bot::Discord::MessageApi).to receive(:edit).and_raise(
          Bot::Discord::MessageApi::Error.new("not found", status: 404)
        )
      end

      it "falls back to creating a fresh message in the currently configured channel" do
        result
        expect(created_messages.first[:channel_id]).to eq(555)
      end

      it "stores the new channel and message ids" do
        result
        game.reload
        expect(game.discord_channel_id).to eq(555)
        expect(game.discord_message_id).to eq(999)
      end
    end

    context "when edit raises a non-404 error" do
      before do
        allow(Bot::Discord::MessageApi).to receive(:edit).and_raise(
          Bot::Discord::MessageApi::Error.new("server error", status: 500)
        )
      end

      it "returns a failure" do
        expect(result).to be_failure
      end

      it "does not fall back to create" do
        result
        expect(Bot::Discord::MessageApi).not_to have_received(:create)
      end

      it "leaves the stored ids unchanged" do
        result
        game.reload
        expect(game.discord_channel_id).to eq(111)
        expect(game.discord_message_id).to eq(222)
      end
    end
  end

  context "when create raises an error" do
    let(:tournament) { create(:twilight_struggle_tournament, discord_channel_id: "555") }

    before do
      allow(Bot::Discord::MessageApi).to receive(:create).and_raise(
        Bot::Discord::MessageApi::Error.new("boom", status: 500)
      )
    end

    it "returns a failure" do
      expect(result).to be_failure
    end
  end

  context "template selection" do
    let(:tournament) { create(:twilight_struggle_tournament, discord_channel_id: "555") }

    context "when video_urls is present" do
      let(:video_urls) { ["https://example.com/1"] }

      it "uses the with-video template" do
        result
        expect(body_text(created_messages.first[:body])).to include("Recording below.")
      end
    end

    context "when video_urls is empty" do
      let(:video_urls) { [] }

      it "uses the without-video template" do
        result
        expect(body_text(created_messages.first[:body])).not_to include("Recording below.")
      end
    end
  end

  context "pings" do
    let(:tournament) { create(:twilight_struggle_tournament, discord_channel_id: "555", ping_players:) }

    context "when ping_players is false" do
      let(:ping_players) { false }

      it "creates a single message with components and locked-down mentions" do
        result
        expect(created_messages.size).to eq(1)
        body = created_messages.first[:body]
        expect(body).to have_key(:components)
        expect(body[:allowed_mentions]).to eq({parse: []})
        expect(body[:allowed_mentions]).not_to have_key(:users)
      end

      it "does not call edit" do
        result
        expect(Bot::Discord::MessageApi).not_to have_received(:edit)
      end
    end

    context "when ping_players is true" do
      let(:ping_players) { true }

      it "creates a plain-text message listing both mentions" do
        result
        body = created_messages.first[:body]
        expect(body[:content]).to eq("<@111> <@222>")
        expect(body[:allowed_mentions]).to eq({parse: [], users: %w[111 222]})
      end

      it "then edits the created message into the components form" do
        result
        edited = edited_messages.first
        expect(edited[:channel_id]).to eq(555)
        expect(edited[:message_id]).to eq("999")
        expect(edited[:body]).to have_key(:components)
        expect(edited[:body][:allowed_mentions]).to eq({parse: []})
      end

      context "when the conversion edit fails" do
        before do
          allow(Bot::Discord::MessageApi).to receive(:edit).and_raise(Bot::Discord::MessageApi::Error.new("boom", status: 500))
        end

        it "still stores the created message location" do
          result
          expect(game.reload.discord_message_id).to eq(999)
        end

        it "reports the failure" do
          expect(result).to be_failure
        end
      end
    end
  end
end
