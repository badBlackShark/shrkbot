# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Ops::TwilightStruggle::Games::Post do
  subject(:result) { described_class.call(game:, report:) }

  def body_text(rendered)
    rendered[:components].first[:components].map { |block| block[:content] }.join
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

  let(:created_components_messages) { [] }
  let(:created_plain_messages) { [] }
  let(:edited_messages) { [] }

  before do
    allow(Bot::Discord::Components).to receive(:create_components_message) do |channel_id:, rendered:, allowed_mentions:|
      created_components_messages << {channel_id:, rendered:, allowed_mentions:}
      "999"
    end
    allow(Bot::Discord::Components).to receive(:create_message) do |channel_id:, content:, allowed_mentions:|
      created_plain_messages << {channel_id:, content:, allowed_mentions:}
      "999"
    end
    allow(Bot::Discord::Components).to receive(:edit_components) do |channel_id, message_id, rendered|
      edited_messages << {channel_id:, message_id:, rendered:}
      nil
    end
  end

  context "when no destination channel is configured anywhere in the chain" do
    it "does not touch the Discord API" do
      result
      expect(Bot::Discord::Components).not_to have_received(:create_components_message)
      expect(Bot::Discord::Components).not_to have_received(:create_message)
      expect(Bot::Discord::Components).not_to have_received(:edit_components)
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
      expect(created_components_messages.first[:channel_id]).to eq(555)
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
      expect(created_components_messages.first[:channel_id]).to eq(777)
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
      expect(Bot::Discord::Components).not_to have_received(:create_components_message)
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

    context "when edit raises Discordrb::Errors::UnknownMessage (message deleted by a human)" do
      before do
        allow(Bot::Discord::Components).to receive(:edit_components).and_raise(
          Discordrb::Errors::UnknownMessage.new("Unknown Message")
        )
      end

      it "falls back to creating a fresh message in the currently configured channel" do
        result
        expect(created_components_messages.first[:channel_id]).to eq(555)
      end

      it "stores the new channel and message ids" do
        result
        game.reload
        expect(game.discord_channel_id).to eq(555)
        expect(game.discord_message_id).to eq(999)
      end
    end

    context "when edit raises a different error" do
      before do
        allow(Bot::Discord::Components).to receive(:edit_components).and_raise(Discordrb::Errors::NoPermission.new("nope"))
      end

      it "propagates the error" do
        expect { result }.to raise_error(Discordrb::Errors::NoPermission)
      end

      it "does not fall back to create" do
        expect { result }.to raise_error(Discordrb::Errors::NoPermission)
        expect(Bot::Discord::Components).not_to have_received(:create_components_message)
      end

      it "leaves the stored ids unchanged" do
        expect { result }.to raise_error(Discordrb::Errors::NoPermission)
        game.reload
        expect(game.discord_channel_id).to eq(111)
        expect(game.discord_message_id).to eq(222)
      end
    end
  end

  context "when create raises an error" do
    let(:tournament) { create(:twilight_struggle_tournament, discord_channel_id: "555") }

    before do
      allow(Bot::Discord::Components).to receive(:create_components_message).and_raise(Discordrb::Errors::NoPermission.new("boom"))
    end

    it "propagates the error" do
      expect { result }.to raise_error(Discordrb::Errors::NoPermission)
    end
  end

  context "template selection" do
    let(:tournament) { create(:twilight_struggle_tournament, discord_channel_id: "555") }

    context "when video_urls is present" do
      let(:video_urls) { ["https://example.com/1"] }

      it "uses the with-video template" do
        result
        expect(body_text(created_components_messages.first[:rendered])).to include("Recording below.")
      end
    end

    context "when video_urls is empty" do
      let(:video_urls) { [] }

      it "uses the without-video template" do
        result
        expect(body_text(created_components_messages.first[:rendered])).not_to include("Recording below.")
      end
    end
  end

  context "pings" do
    let(:tournament) { create(:twilight_struggle_tournament, discord_channel_id: "555", ping_players:) }

    context "when ping_players is false" do
      let(:ping_players) { false }

      it "creates a single components message with locked-down mentions" do
        result
        expect(created_components_messages.size).to eq(1)
        expect(created_plain_messages).to be_empty
        expect(created_components_messages.first[:allowed_mentions]).to eq({parse: []})
      end

      it "does not call edit" do
        result
        expect(Bot::Discord::Components).not_to have_received(:edit_components)
      end
    end

    context "when ping_players is true" do
      let(:ping_players) { true }

      it "creates a plain-text message listing both mentions" do
        result
        plain = created_plain_messages.first
        expect(plain[:content]).to eq("<@111> <@222>")
        expect(plain[:allowed_mentions]).to eq({parse: [], users: %w[111 222]})
      end

      it "then edits the created message into the components form" do
        result
        edited = edited_messages.first
        expect(edited[:channel_id]).to eq(555)
        expect(edited[:message_id]).to eq("999")
        expect(edited[:rendered]).to have_key(:components)
      end

      context "when the conversion edit fails" do
        before do
          allow(Bot::Discord::Components).to receive(:edit_components).and_raise(Discordrb::Errors::NoPermission.new("boom"))
        end

        it "still stores the created message location before raising" do
          expect { result }.to raise_error(Discordrb::Errors::NoPermission)
          expect(game.reload.discord_message_id).to eq(999)
        end
      end
    end
  end
end
