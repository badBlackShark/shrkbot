# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::Game do
  subject(:game) { build(:twilight_struggle_game) }

  it "is valid from the factory" do
    expect(game).to be_valid
  end

  describe "external_id" do
    it "is invalid when nil" do
      game.external_id = nil
      expect(game).not_to be_valid
    end

    context "when another game already uses the id" do
      let!(:existing) { create(:twilight_struggle_game) }

      it "is invalid" do
        duplicate = build(:twilight_struggle_game, external_id: existing.external_id)
        expect(duplicate).not_to be_valid
      end
    end
  end

  describe "tournament" do
    it "is required" do
      game.tournament = nil
      expect(game).not_to be_valid
    end
  end
end
