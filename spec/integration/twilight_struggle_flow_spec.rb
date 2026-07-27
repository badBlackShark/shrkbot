# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Twilight Struggle integration", type: :request, skip_prosopite: true do
  include_context "twilight struggle api auth"
  include ActiveJob::TestHelper

  let(:external_id) { "tsg-flow-1" }
  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:server_configuration) { create(:server_configuration, name: "Test Server") }
  let(:twilight_struggle_plugin) { create(:plugin, key: "twilight_struggle", name: "Twilight Struggle") }

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

  def subscribe(server:, tournament:, **destination_attrs)
    create(:bespoke_plugin_grant, server_configuration: server, plugin_key: "twilight_struggle")
    create(:plugin_activation, server_configuration: server, plugin: twilight_struggle_plugin, enabled: true)
    create(:twilight_struggle_destination, tournament:, server_configuration: server, **destination_attrs)
  end

  def base_game_attributes
    {
      game_code: "R1",
      game_date: "2026-07-20",
      reported_at: "2026-07-24T10:00:00Z",
      winning_side: "usa",
      winning_turn: 6,
      winning_method: "Objectives",
      usa: {name: "Alice", flag: "🇺🇸"},
      ussr: {name: "Bob", flag: "🇷🇺"}
    }
  end

  def game_attributes(overrides = {})
    base_game_attributes.merge(tournament_external_id: tournament.external_id).merge(overrides)
  end

  def friendly_game_attributes(overrides = {})
    base_game_attributes.merge(overrides)
  end

  def put_game(external_id, attributes)
    put api_twilight_struggle_v1_game_path(external_id), params: {game: attributes}, headers:, as: :json
  end

  def delete_game(external_id)
    delete api_twilight_struggle_v1_game_path(external_id), headers:
  end

  def delete_tournament(external_id)
    delete api_twilight_struggle_v1_tournament_path(external_id), headers:
  end

  context "when no server subscribes to the tournament" do
    subject(:post_game) { perform_enqueued_jobs { put_game(external_id, game_attributes) } }

    it "never calls create_message" do
      post_game

      expect(Bot::Discord::Components).not_to have_received(:create_message)
    end
  end

  context "when the subscribed server's plugin is disabled" do
    let!(:grant) { create(:bespoke_plugin_grant, server_configuration:, plugin_key: "twilight_struggle") }
    let!(:activation) { create(:plugin_activation, server_configuration:, plugin: twilight_struggle_plugin, enabled: false) }
    let!(:destination) { create(:twilight_struggle_destination, tournament:, server_configuration:, discord_channel_id: 555) }

    subject(:post_game) { perform_enqueued_jobs { put_game(external_id, game_attributes) } }

    it "never calls create_message" do
      post_game

      expect(Bot::Discord::Components).not_to have_received(:create_message)
    end
  end

  context "when the subscribed server has no channel configured anywhere in its chain" do
    let!(:destination) { subscribe(server: server_configuration, tournament:, discord_channel_id: nil) }

    subject(:post_game) { perform_enqueued_jobs { put_game(external_id, game_attributes) } }

    it "never calls create_message" do
      post_game

      expect(Bot::Discord::Components).not_to have_received(:create_message)
    end
  end

  context "when a subscribed server has a channel configured" do
    let!(:destination) { subscribe(server: server_configuration, tournament:, discord_channel_id: 555) }

    subject(:post_game) { perform_enqueued_jobs { put_game(external_id, game_attributes) } }

    it "calls create_message exactly once" do
      post_game

      expect(Bot::Discord::Components).to have_received(:create_message).once
    end

    it "posts to the configured channel" do
      post_game

      expect(created_messages.first[:channel_id]).to eq(555)
    end

    it "includes both player names in the content" do
      post_game

      expect(created_messages.first[:content]).to include("Alice").and include("Bob")
    end

    context "when the same external_id is put again with a corrected result" do
      before { post_game }

      subject(:correct_result) do
        perform_enqueued_jobs { put_game(external_id, game_attributes(winning_side: "ussr", winning_method: "Coup")) }
      end

      it "still calls create_message only once overall" do
        correct_result

        expect(Bot::Discord::Components).to have_received(:create_message).once
      end

      it "calls edit_content for the correction" do
        correct_result

        expect(Bot::Discord::Components).to have_received(:edit_content).once
      end

      it "does not create a second posted-message row" do
        expect { correct_result }.not_to change(TwilightStruggle::PostedMessage, :count)
      end
    end

    context "when the result is a tie" do
      subject(:post_tie) { perform_enqueued_jobs { put_game(external_id, game_attributes(winning_side: "tie")) } }

      it "uses the tie template" do
        post_tie

        expect(created_messages.first[:content]).to include("tied with")
      end
    end

    context "when winning_turn is 11" do
      subject(:post_final) { perform_enqueued_jobs { put_game(external_id, game_attributes(winning_turn: 11)) } }

      it "renders Final Scoring rather than Turn 11" do
        post_final

        expect(created_messages.first[:content]).to include("Final Scoring")
        expect(created_messages.first[:content]).not_to include("Turn 11")
      end
    end

    context "when the game has video_urls" do
      subject(:post_video) do
        perform_enqueued_jobs { put_game(external_id, game_attributes(video_urls: ["https://example.com/clip"])) }
      end

      it "uses the video template even though the game was decided" do
        post_video

        expect(created_messages.first[:content]).to include("https://example.com/clip")
      end

      it "is spoiler-free" do
        post_video

        content = created_messages.first[:content]
        expect(content).not_to include("Objectives")
        expect(content).not_to include("Turn 6")
        expect(content).not_to include("defeated")
      end
    end

    context "when the destination has ping_players enabled" do
      let!(:destination) { subscribe(server: server_configuration, tournament:, discord_channel_id: 555, ping_players: true) }

      subject(:post_with_ping) do
        perform_enqueued_jobs do
          put_game(external_id, game_attributes(usa: {name: "Alice", flag: "🇺🇸", discord_id: "111"}, ussr: {name: "Bob", flag: "🇷🇺"}))
        end
      end

      it "puts the player's name before their tag, never replacing it" do
        post_with_ping

        expect(created_messages.first[:content]).to include("Alice 🇺🇸 (<@111>)")
      end

      it "leaves the player without a discord_id plain" do
        post_with_ping

        content = created_messages.first[:content]
        expect(content).to include("Bob 🇷🇺")
        expect(content).not_to include("Bob 🇷🇺 (<@")
      end
    end
  end

  context "when the game is on a child tournament and only the parent has a destination" do
    let(:parent_tournament) { create(:twilight_struggle_tournament) }
    let(:tournament) { create(:twilight_struggle_tournament, parent: parent_tournament) }
    let!(:destination) do
      subscribe(
        server: server_configuration,
        tournament: parent_tournament,
        discord_channel_id: 777,
        template_win: "PARENT TEMPLATE: {winning_player} beat {losing_player}"
      )
    end

    subject(:post_game) { perform_enqueued_jobs { put_game(external_id, game_attributes) } }

    it "posts to the parent's channel" do
      post_game

      expect(created_messages.first[:channel_id]).to eq(777)
    end

    it "uses the parent's template" do
      post_game

      expect(created_messages.first[:content]).to start_with("PARENT TEMPLATE:")
    end
  end

  context "when two servers subscribe to the same tournament" do
    let(:server_a) { create(:server_configuration, name: "Server A") }
    let(:server_b) { create(:server_configuration, name: "Server B") }
    let!(:destination_a) do
      subscribe(server: server_a, tournament:, discord_channel_id: 111, template_win: "SERVER A: {winning_player} won")
    end
    let!(:destination_b) do
      subscribe(server: server_b, tournament:, discord_channel_id: 222, template_win: "SERVER B: {winning_player} won")
    end

    subject(:post_game) { perform_enqueued_jobs { put_game(external_id, game_attributes) } }

    it "calls create_message once per server" do
      post_game

      expect(Bot::Discord::Components).to have_received(:create_message).twice
    end

    it "posts to each server's own channel with its own wording" do
      post_game

      message_a = created_messages.find { |message| message[:channel_id] == 111 }
      message_b = created_messages.find { |message| message[:channel_id] == 222 }
      expect(message_a[:content]).to include("SERVER A:")
      expect(message_b[:content]).to include("SERVER B:")
    end

    it "never allows mentions on any call" do
      post_game

      expect(created_messages).to all(include(allowed_mentions: {parse: []}))
    end

    context "when one of the two servers has the plugin disabled" do
      let!(:disable_server_b) do
        PluginActivation.find_by!(server_configuration: server_b, plugin: twilight_struggle_plugin).update!(enabled: false)
      end

      it "posts only to the enabled server" do
        post_game

        expect(Bot::Discord::Components).to have_received(:create_message).once
        expect(created_messages.first[:channel_id]).to eq(111)
      end
    end
  end

  context "when a game is put with no tournament_external_id" do
    subject(:put_first_friendly) do
      perform_enqueued_jobs { put_game("tsg-friendly-1", friendly_game_attributes) }
    end

    it "creates the singleton friendly tournament" do
      expect { put_first_friendly }.to change(TwilightStruggle::Tournament, :count).by(1)
    end

    it "attaches the game to a friendly tournament" do
      put_first_friendly

      expect(TwilightStruggle::Game.find_by(external_id: "tsg-friendly-1").tournament).to be_friendly
    end

    context "when a second such game is put" do
      before { put_first_friendly }

      subject(:put_second_friendly) do
        perform_enqueued_jobs { put_game("tsg-friendly-2", friendly_game_attributes) }
      end

      it "reuses the same friendly tournament row rather than creating another" do
        expect { put_second_friendly }.not_to change(TwilightStruggle::Tournament, :count)
      end

      it "attaches both games to the same tournament" do
        put_second_friendly

        first_tournament = TwilightStruggle::Game.find_by(external_id: "tsg-friendly-1").tournament
        second_tournament = TwilightStruggle::Game.find_by(external_id: "tsg-friendly-2").tournament
        expect(second_tournament).to eq(first_tournament)
      end
    end
  end

  context "deleting a game that posted to two servers" do
    let(:server_a) { create(:server_configuration) }
    let(:server_b) { create(:server_configuration) }
    let!(:destination_a) { subscribe(server: server_a, tournament:, discord_channel_id: 111) }
    let!(:destination_b) { subscribe(server: server_b, tournament:, discord_channel_id: 222) }

    before { perform_enqueued_jobs { put_game(external_id, game_attributes) } }

    subject(:delete_action) { delete_game(external_id) }

    it "enqueues a delete job for each posted message" do
      expect { delete_action }.to change {
        ActiveJob::Base.queue_adapter.enqueued_jobs.count { |job| job[:job] == TwilightStruggle::DeleteMessageJob }
      }.by(2)
    end
  end

  context "deleting a tournament whose games already posted" do
    let!(:destination) { subscribe(server: server_configuration, tournament:, discord_channel_id: 555) }

    before { perform_enqueued_jobs { put_game(external_id, game_attributes) } }

    subject(:delete_action) { delete_tournament(tournament.external_id) }

    it "deletes the tournament's games" do
      expect { delete_action }.to change(TwilightStruggle::Game, :count).by(-1)
    end

    it "does not enqueue a delete job for the already-posted message" do
      expect { delete_action }.not_to have_enqueued_job(TwilightStruggle::DeleteMessageJob)
    end
  end
end
