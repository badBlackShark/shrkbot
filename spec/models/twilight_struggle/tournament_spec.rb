# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::Tournament do
  subject(:tournament) { build(:twilight_struggle_tournament) }

  it "is valid from the factory" do
    expect(tournament).to be_valid
  end

  describe "external_id" do
    it "is required when not friendly" do
      tournament.external_id = nil
      expect(tournament).not_to be_valid
    end

    it "must be absent when friendly" do
      tournament.friendly = true
      expect(tournament).not_to be_valid
    end

    context "when another tournament already uses the id" do
      let!(:existing) { create(:twilight_struggle_tournament) }

      it "is invalid" do
        duplicate = build(:twilight_struggle_tournament, external_id: existing.external_id)
        expect(duplicate).not_to be_valid
      end
    end
  end

  describe "friendly uniqueness" do
    let!(:existing) { create(:twilight_struggle_tournament, friendly: true, external_id: nil) }

    it "raises at the database level for a second friendly tournament" do
      expect {
        create(:twilight_struggle_tournament, friendly: true, external_id: nil)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#archived?" do
    it "is true when archived_at is set" do
      tournament.archived_at = Time.current
      expect(tournament.archived?).to be(true)
    end

    it "is true when status is closed" do
      tournament.status = TwilightStruggle::Tournament::CLOSED_STATUS
      expect(tournament.archived?).to be(true)
    end

    it "is false otherwise" do
      tournament.archived_at = nil
      tournament.status = "open"
      expect(tournament.archived?).to be(false)
    end
  end

  describe "#parent" do
    it "rejects a self-parent" do
      persisted = create(:twilight_struggle_tournament)
      persisted.parent = persisted

      expect(persisted).not_to be_valid
      expect(persisted.errors[:parent]).to include("would create a loop")
    end

    it "rejects a two-record loop" do
      first = create(:twilight_struggle_tournament)
      second = create(:twilight_struggle_tournament, parent: first)
      first.parent = second

      expect(first).not_to be_valid
      expect(first.errors[:parent]).to include("would create a loop")
    end
  end

  describe "destroying a parent" do
    let!(:parent) { create(:twilight_struggle_tournament) }
    let!(:child) { create(:twilight_struggle_tournament, parent:) }
    let!(:game) { create(:twilight_struggle_game, tournament: child) }

    it "destroys its children and their games" do
      parent.destroy

      expect(described_class.find_by(id: child.id)).to be_nil
      expect(TwilightStruggle::Game.find_by(id: game.id)).to be_nil
    end
  end
end
