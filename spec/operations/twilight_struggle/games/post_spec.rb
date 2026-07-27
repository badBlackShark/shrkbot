# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Ops::TwilightStruggle::Games::Post do
  subject(:result) { described_class.call(game:, server_configuration:, report:) }

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

  let(:server_configuration) { create(:server_configuration, name: "Test Server") }
  let(:twilight_struggle_plugin) { create(:plugin, key: "twilight_struggle", name: "Twilight Struggle") }
  let!(:grant) { create(:bespoke_plugin_grant, server_configuration:, plugin_key: "twilight_struggle") }
  let!(:activation) { create(:plugin_activation, server_configuration:, plugin: twilight_struggle_plugin, enabled: true) }

  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:game) { create(:twilight_struggle_game, tournament:) }

  let(:created_messages) { [] }
  let(:edited_messages) { [] }

  before do
    allow(Bot::Discord::Components).to receive(:create_message) do |channel_id:, content:, allowed_mentions:|
      created_messages << {channel_id:, content:, allowed_mentions:}
      "999"
    end
    allow(Bot::Discord::Components).to receive(:edit_content) do |channel_id, message_id, content|
      edited_messages << {channel_id:, message_id:, content:}
      nil
    end
  end

  context "when this server has no channel configured anywhere in the chain" do
    it "logs which gate stopped it, since the job would otherwise finish silently" do
      allow(Rails.logger).to receive(:info)
      result
      expect(Rails.logger).to have_received(:info) do |&block|
        expect(block.call).to include("no channel").and include(server_configuration.name)
      end
    end

    it "does not touch the Discord API" do
      result
      expect(Bot::Discord::Components).not_to have_received(:create_message)
      expect(Bot::Discord::Components).not_to have_received(:edit_content)
    end

    it "returns success" do
      expect(result).to be_success
    end

    it "writes no posted-message row" do
      result
      expect(game.reload.posted_messages).to be_empty
    end
  end

  context "when a channel is configured but the plugin is disabled on this server" do
    let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, discord_channel_id: 555) }
    let!(:activation) { create(:plugin_activation, server_configuration:, plugin: twilight_struggle_plugin, enabled: false) }

    it "names the disabled plugin as the reason" do
      allow(Rails.logger).to receive(:info)
      result
      expect(Rails.logger).to have_received(:info) do |&block|
        expect(block.call).to include("plugin is disabled")
      end
    end

    it "does not touch the Discord API" do
      result
      expect(Bot::Discord::Components).not_to have_received(:create_message)
    end

    it "returns success" do
      expect(result).to be_success
    end
  end

  context "when the destination is configured directly on this server" do
    let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, discord_channel_id: 555) }

    it "creates in that channel" do
      result
      expect(created_messages.first[:channel_id]).to eq(555)
    end

    it "logs where it landed, naming this server, so a live post can be traced" do
      allow(Rails.logger).to receive(:info)
      result
      expect(Rails.logger).to have_received(:info) do |&block|
        expect(block.call).to include("posted game").and include("999").and include("555").and include(server_configuration.name)
      end
    end

    it "writes a posted-message row for this game and server" do
      result
      posted = game.reload.posted_messages.find_by(server_configuration:)
      expect(posted.discord_channel_id).to eq(555)
      expect(posted.discord_message_id).to eq(999)
    end
  end

  context "when the destination is inherited from the parent tournament" do
    let(:parent_tournament) { create(:twilight_struggle_tournament) }
    let(:tournament) { create(:twilight_struggle_tournament, parent: parent_tournament) }
    let!(:destination) { create(:twilight_struggle_destination, tournament: parent_tournament, server_configuration:, discord_channel_id: 777) }

    it "creates in the parent's channel" do
      result
      expect(created_messages.first[:channel_id]).to eq(777)
    end
  end

  context "when this game already has a posted message for this server" do
    let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, discord_channel_id: 555) }
    let!(:posted_message) do
      create(:twilight_struggle_posted_message, game:, server_configuration:, discord_channel_id: 111, discord_message_id: 222)
    end

    it "edits in place at the stored channel id" do
      result
      expect(edited_messages.first[:channel_id]).to eq(111)
      expect(edited_messages.first[:message_id]).to eq(222)
    end

    it "does not call create" do
      result
      expect(Bot::Discord::Components).not_to have_received(:create_message)
    end

    it "leaves the stored ids unchanged" do
      result
      posted_message.reload
      expect(posted_message.discord_channel_id).to eq(111)
      expect(posted_message.discord_message_id).to eq(222)
    end

    it "does not create a second posted-message row" do
      expect { result }.not_to change(TwilightStruggle::PostedMessage, :count)
    end

    context "when the destination's configured channel has since changed" do
      it "still edits the old stored channel, not the currently configured one" do
        result
        expect(edited_messages.first[:channel_id]).to eq(111)
      end
    end

    context "when edit raises Discordrb::Errors::UnknownMessage (message deleted by a human)" do
      before do
        allow(Bot::Discord::Components).to receive(:edit_content).and_raise(
          Discordrb::Errors::UnknownMessage.new("Unknown Message")
        )
      end

      it "falls back to creating a fresh message in the currently configured channel" do
        result
        expect(created_messages.first[:channel_id]).to eq(555)
      end

      it "stores the new channel and message ids on the same row" do
        result
        posted_message.reload
        expect(posted_message.discord_channel_id).to eq(555)
        expect(posted_message.discord_message_id).to eq(999)
      end
    end

    context "when edit raises a different error" do
      before do
        allow(Bot::Discord::Components).to receive(:edit_content).and_raise(Discordrb::Errors::NoPermission.new("nope"))
      end

      it "propagates the error" do
        expect { result }.to raise_error(Discordrb::Errors::NoPermission)
      end

      it "does not fall back to create" do
        expect { result }.to raise_error(Discordrb::Errors::NoPermission)
        expect(Bot::Discord::Components).not_to have_received(:create_message)
      end

      it "leaves the stored ids unchanged" do
        expect { result }.to raise_error(Discordrb::Errors::NoPermission)
        posted_message.reload
        expect(posted_message.discord_channel_id).to eq(111)
        expect(posted_message.discord_message_id).to eq(222)
      end
    end
  end

  context "when a different server already has a posted message for this game" do
    let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, discord_channel_id: 555) }
    let(:other_server) { create(:server_configuration) }
    let!(:other_posted_message) do
      create(:twilight_struggle_posted_message, game:, server_configuration: other_server, discord_channel_id: 111, discord_message_id: 222)
    end

    it "creates a new message for this server rather than editing the other server's" do
      result
      expect(created_messages.first[:channel_id]).to eq(555)
      expect(Bot::Discord::Components).not_to have_received(:edit_content)
    end

    it "writes a separate posted-message row for this server" do
      result
      expect(game.reload.posted_messages.count).to eq(2)
    end
  end

  context "when create raises an error" do
    let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, discord_channel_id: 555) }

    before do
      allow(Bot::Discord::Components).to receive(:create_message).and_raise(Discordrb::Errors::NoPermission.new("boom"))
    end

    it "propagates the error" do
      expect { result }.to raise_error(Discordrb::Errors::NoPermission)
    end
  end

  context "template selection" do
    let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, discord_channel_id: 555) }

    context "when video_urls is present" do
      let(:video_urls) { ["https://example.com/1"] }

      it "uses the video template, spoiler-free even on a decided game" do
        result
        content = created_messages.first[:content]
        expect(content).to include("https://example.com/1")
        expect(content).not_to include("defeated")
        expect(content).not_to include("defcon")
      end
    end

    context "when video_urls is empty and the game is a tie" do
      let(:report) do
        TwilightStruggle::GameReport.new(usa:, ussr:, winning_side: "tie", winning_turn: 6, winning_method: "defcon", game_code: "R1")
      end

      it "uses the tie template" do
        result
        expect(created_messages.first[:content]).to include("tied with")
      end
    end

    context "when video_urls is empty and the game is decided" do
      it "uses the win template" do
        result
        expect(created_messages.first[:content]).to include("has defeated")
      end
    end
  end

  context "discord tags" do
    let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, discord_channel_id: 555, ping_players:) }

    context "when tags are off" do
      let(:ping_players) { false }

      it "creates a single message" do
        result
        expect(created_messages.size).to eq(1)
      end

      it "renders plain names" do
        result
        expect(created_messages.first[:content]).not_to include("<@")
      end

      it "does not call edit" do
        result
        expect(Bot::Discord::Components).not_to have_received(:edit_content)
      end
    end

    context "when tags are on" do
      let(:ping_players) { true }

      it "renders each tag next to the name it belongs to" do
        result
        expect(created_messages.first[:content]).to include("Alice 🇺🇸 (<@111>)").and include("Bob 🇷🇺 (<@222>)")
      end

      it "still notifies nobody" do
        result
        expect(created_messages.first[:allowed_mentions]).to eq({parse: []})
      end
    end
  end
end
