# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::TournamentAdmin do
  subject(:admin) { build(:twilight_struggle_tournament_admin) }

  it "is valid from the factory" do
    expect(admin).to be_valid
  end

  describe "discord_id" do
    it "is required" do
      admin.discord_id = nil
      expect(admin).not_to be_valid
    end

    context "when another admin already has that discord_id on the same tournament" do
      let!(:existing) { create(:twilight_struggle_tournament_admin) }

      it "is invalid" do
        duplicate = build(
          :twilight_struggle_tournament_admin,
          tournament: existing.tournament,
          discord_id: existing.discord_id
        )
        expect(duplicate).not_to be_valid
      end
    end

    context "when the same discord_id is on a different tournament" do
      let!(:existing) { create(:twilight_struggle_tournament_admin) }

      it "is valid" do
        duplicate = build(:twilight_struggle_tournament_admin, discord_id: existing.discord_id)
        expect(duplicate).to be_valid
      end
    end
  end
end
