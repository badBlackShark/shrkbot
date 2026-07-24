# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::TwilightStruggle::Games::Upsert do
  subject(:result) { described_class.call(external_id:, tournament:) }

  let(:external_id) { "ext-game-1" }
  let(:tournament) { create(:twilight_struggle_tournament) }

  it "creates a game when none exists" do
    expect { result }.to change(TwilightStruggle::Game, :count).by(1)
  end

  it "attaches the game to the given tournament" do
    expect(result.value.tournament).to eq(tournament)
  end

  context "when a game with the external_id already exists" do
    let!(:existing) { create(:twilight_struggle_game, external_id:) }

    it "updates the row in place" do
      expect { result }.not_to change(TwilightStruggle::Game, :count)
      expect(existing.reload.tournament).to eq(tournament)
    end
  end

  context "when no tournament is passed" do
    let(:tournament) { nil }

    it "attaches to the friendly tournament, creating it on first use" do
      expect { result }.to change { TwilightStruggle::Tournament.where(friendly: true).count }.by(1)
      expect(result.value.tournament.friendly).to be(true)
    end

    context "when a friendly game already exists" do
      before { described_class.call(external_id: "ext-game-0", tournament: nil) }

      it "reuses the same friendly tournament" do
        result
        expect(TwilightStruggle::Tournament.where(friendly: true).count).to eq(1)
      end
    end
  end
end
