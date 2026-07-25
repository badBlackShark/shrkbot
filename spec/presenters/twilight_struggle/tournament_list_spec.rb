# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::TournamentList do
  subject(:tournaments) { described_class.new(server_configurations:, owner:, archived:).all }

  let(:mine) { create(:server_configuration) }
  let(:theirs) { create(:server_configuration) }
  let(:server_configurations) { ServerConfiguration.where(id: mine.id) }
  let(:owner) { false }
  let(:archived) { false }

  let!(:claimed_by_me) { create(:twilight_struggle_tournament, name: "Mine", server_configuration: mine) }
  let!(:claimed_by_them) { create(:twilight_struggle_tournament, name: "Theirs", server_configuration: theirs) }
  let!(:unclaimed) { create(:twilight_struggle_tournament, name: "Up for grabs") }

  it "shows the tournaments claimed by the user's servers and every unclaimed one" do
    expect(tournaments).to contain_exactly(claimed_by_me, unclaimed)
  end

  it "orders by name" do
    expect(tournaments.map(&:name)).to eq(["Mine", "Up for grabs"])
  end

  context "when the user is the bot owner" do
    let(:owner) { true }

    it "shows every tournament" do
      expect(tournaments).to contain_exactly(claimed_by_me, claimed_by_them, unclaimed)
    end
  end

  describe "archived tournaments" do
    let!(:manually_archived) { create(:twilight_struggle_tournament, server_configuration: mine, archived_at: 1.day.ago) }
    let!(:closed_upstream) { create(:twilight_struggle_tournament, server_configuration: mine, status: "closed") }

    it "hides them by default" do
      expect(tournaments).not_to include(manually_archived, closed_upstream)
    end

    context "with a tournament the site marked ongoing" do
      let!(:ongoing) { create(:twilight_struggle_tournament, server_configuration: mine, status: "ongoing") }

      it "keeps it visible" do
        expect(tournaments).to include(ongoing)
      end
    end

    context "when asking for the archived list" do
      let(:archived) { true }

      it "shows only the archived ones" do
        expect(tournaments).to contain_exactly(manually_archived, closed_upstream)
      end
    end
  end
end
