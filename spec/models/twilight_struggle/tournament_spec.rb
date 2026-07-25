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

  describe "#chain" do
    let(:grandparent) { create(:twilight_struggle_tournament) }
    let(:parent) { create(:twilight_struggle_tournament, parent: grandparent) }
    let(:tournament) { create(:twilight_struggle_tournament, parent:) }

    it "returns itself first" do
      expect(tournament.chain.first).to eq(tournament)
    end

    it "walks up to the ancestors, nearest first" do
      expect(tournament.chain).to eq([tournament, parent, grandparent])
    end

    context "when there is no parent" do
      let(:tournament) { create(:twilight_struggle_tournament) }

      it "returns just itself" do
        expect(tournament.chain).to eq([tournament])
      end
    end
  end

  describe "#subscribed_servers" do
    let(:parent) { create(:twilight_struggle_tournament) }
    let(:tournament) { create(:twilight_struggle_tournament, parent:) }
    let(:direct_subscriber) { create(:server_configuration) }
    let(:ancestor_subscriber) { create(:server_configuration) }
    let(:elsewhere_subscriber) { create(:server_configuration) }
    let(:unrelated_tournament) { create(:twilight_struggle_tournament) }

    before do
      create(:twilight_struggle_destination, tournament:, server_configuration: direct_subscriber)
      create(:twilight_struggle_destination, tournament: parent, server_configuration: ancestor_subscriber)
      create(:twilight_struggle_destination, tournament: unrelated_tournament, server_configuration: elsewhere_subscriber)
    end

    it "finds a server subscribed directly to the tournament" do
      expect(tournament.subscribed_servers).to include(direct_subscriber)
    end

    it "finds a server subscribed to an ancestor" do
      expect(tournament.subscribed_servers).to include(ancestor_subscriber)
    end

    it "excludes a server subscribed to an unrelated tournament" do
      expect(tournament.subscribed_servers).not_to include(elsewhere_subscriber)
    end

    it "does not duplicate a server subscribed to both the tournament and an ancestor" do
      create(:twilight_struggle_destination, tournament: parent, server_configuration: direct_subscriber)

      expect(tournament.subscribed_servers.where(id: direct_subscriber.id).count).to eq(1)
    end
  end
end
