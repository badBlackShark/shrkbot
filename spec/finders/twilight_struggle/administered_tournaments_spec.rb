# frozen_string_literal: true

require "rails_helper"

RSpec.describe Finders::TwilightStruggle::AdministeredTournaments do
  subject(:administered_tournaments) { described_class.new(discord_id) }

  let(:discord_id) { 700_000_000_000_000_001 }

  describe "#ids" do
    subject(:ids) { administered_tournaments.ids }

    context "when the user has no admin rows" do
      it "is empty" do
        expect(ids).to be_empty
      end
    end

    context "when the user administers a tournament" do
      let(:tournament) { create(:twilight_struggle_tournament) }

      let!(:tournament_admin) { create(:twilight_struggle_tournament_admin, tournament:, discord_id:) }

      it "contains that tournament" do
        expect(ids).to include(tournament.id)
      end

      context "with a child and a grandchild" do
        let(:child) { create(:twilight_struggle_tournament, parent: tournament) }
        let(:grandchild) { create(:twilight_struggle_tournament, parent: child) }

        before do
          child
          grandchild
        end

        it "contains the child and the grandchild" do
          expect(ids).to include(child.id, grandchild.id)
        end
      end

      context "with a parent" do
        let(:parent) { create(:twilight_struggle_tournament) }
        let(:tournament) { create(:twilight_struggle_tournament, parent:) }

        it "does not contain the parent" do
          expect(ids).not_to include(parent.id)
        end
      end

      context "with an unrelated tournament" do
        let!(:unrelated) { create(:twilight_struggle_tournament) }

        it "does not contain it" do
          expect(ids).not_to include(unrelated.id)
        end
      end
    end
  end

  describe "#include?" do
    subject(:included) { administered_tournaments.include?(tournament) }

    let(:tournament) { create(:twilight_struggle_tournament) }

    context "when the user administers the tournament" do
      let!(:tournament_admin) { create(:twilight_struggle_tournament_admin, tournament:, discord_id:) }

      it { is_expected.to be(true) }
    end

    context "when the user does not administer the tournament" do
      it { is_expected.to be(false) }
    end
  end
end
