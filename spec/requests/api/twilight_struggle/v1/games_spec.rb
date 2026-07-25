# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::TwilightStruggle::V1::Games", type: :request do
  include_context "twilight struggle api auth"

  let(:external_id) { "tsg-ext-new" }
  let(:tournament) { create(:twilight_struggle_tournament) }
  let(:valid_result_attributes) do
    {
      game_code: "R1",
      game_date: "2026-07-20",
      reported_at: "2026-07-24T10:00:00Z",
      winning_side: "usa",
      winning_turn: 6,
      winning_method: "Objectives",
      usa: {name: "Alice", flag: "🇺🇸"},
      ussr: {name: "Bob", flag: "🇷🇺"},
      video_urls: ["https://example.com/video"]
    }
  end
  let(:params) { {game: valid_result_attributes.merge(tournament_external_id: tournament.external_id)} }

  describe "PUT /api/twilight-struggle/v1/games/:external_id" do
    subject(:put_game) do
      put api_twilight_struggle_v1_game_path(external_id), params:, headers:, as: :json
    end

    context "without an Authorization header" do
      let(:headers) { {} }

      it "returns 401" do
        put_game

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a wrong token" do
      let(:headers) { {"Authorization" => "Bearer wrong-token"} }

      it "returns 401" do
        put_game

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with the second configured key" do
      let(:headers) { {"Authorization" => "Bearer key-two"} }

      it "authenticates" do
        put_game

        expect(response).to have_http_status(:created)
      end
    end

    context "when TWILIGHT_STRUGGLE_API_KEYS is blank" do
      before do
        allow(ENV).to receive(:fetch).with("TWILIGHT_STRUGGLE_API_KEYS", "").and_return("")
      end

      it "rejects even a plausible token" do
        put_game

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a new external_id and a known tournament" do
      it "returns 201" do
        put_game

        expect(response).to have_http_status(:created)
      end

      it "creates a row attached to the referenced tournament" do
        put_game

        game = TwilightStruggle::Game.find_by(external_id:)
        expect(game.tournament).to eq(tournament)
      end

      it "returns the id and external_id in the body" do
        put_game

        body = response.parsed_body
        expect(body["external_id"]).to eq(external_id)
        expect(body["id"]).to be_present
      end

      it "does not persist any result data on the game row" do
        put_game

        game = TwilightStruggle::Game.find_by(external_id:)
        expect(game.attributes.keys).to match_array(
          %w[id external_id tournament_id discord_channel_id discord_message_id created_at updated_at]
        )
      end
    end

    context "with an external_id that already exists" do
      let!(:game) { create(:twilight_struggle_game, external_id:, tournament: create(:twilight_struggle_tournament)) }

      it "returns 200" do
        put_game

        expect(response).to have_http_status(:ok)
      end

      it "updates in place instead of creating a new row" do
        expect { put_game }.not_to change(TwilightStruggle::Game, :count)
      end

      it "changes the referenced tournament" do
        expect { put_game }.to change { game.reload.tournament }.to(tournament)
      end
    end

    context "with an unknown tournament_external_id" do
      let(:params) { {game: valid_result_attributes.merge(tournament_external_id: "does-not-exist")} }

      it "returns 422" do
        put_game

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create a game row" do
        expect { put_game }.not_to change(TwilightStruggle::Game, :count)
      end
    end

    context "without a tournament_external_id" do
      let(:params) { {game: valid_result_attributes} }

      it "returns 201" do
        put_game

        expect(response).to have_http_status(:created)
      end

      it "attaches the game to the friendly tournament" do
        put_game

        game = TwilightStruggle::Game.find_by(external_id:)
        expect(game.tournament.friendly?).to be true
      end
    end

    context "with a player object missing its name" do
      let(:params) { {game: valid_result_attributes.merge(tournament_external_id: tournament.external_id, usa: {flag: "🇺🇸"})} }

      it "returns 422" do
        put_game

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with an invalid winning_side" do
      let(:params) { {game: valid_result_attributes.merge(tournament_external_id: tournament.external_id, winning_side: "nope")} }

      it "returns 422" do
        put_game

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with a winning_turn outside 1-11" do
      let(:params) { {game: valid_result_attributes.merge(tournament_external_id: tournament.external_id, winning_turn: 12)} }

      it "returns 422" do
        put_game

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with a javascript: URL in video_urls" do
      let(:params) do
        {game: valid_result_attributes.merge(tournament_external_id: tournament.external_id, video_urls: ["javascript:alert(1)"])}
      end

      it "returns 422" do
        put_game

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with a non-string entry in video_urls" do
      let(:params) do
        {game: valid_result_attributes.merge(tournament_external_id: tournament.external_id, video_urls: [123])}
      end

      it "returns 422 rather than erroring" do
        put_game

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /api/twilight-struggle/v1/games/:external_id" do
    subject(:delete_game) do
      delete api_twilight_struggle_v1_game_path(external_id), headers:
    end

    context "when the game exists" do
      let!(:game) { create(:twilight_struggle_game, external_id:) }

      it "returns 204" do
        delete_game

        expect(response).to have_http_status(:no_content)
      end

      it "deletes the row" do
        expect { delete_game }.to change(TwilightStruggle::Game, :count).by(-1)
      end
    end

    context "when the external_id does not exist" do
      it "returns 204" do
        delete_game

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
