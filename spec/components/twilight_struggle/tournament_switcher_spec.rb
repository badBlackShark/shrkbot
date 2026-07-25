# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::TwilightStruggle::TournamentSwitcher do
  include Rails.application.routes.url_helpers

  include_context "component view context"

  subject(:html) { described_class.new(current:, tournaments:).render_in(view_context) }

  let(:current) { create(:twilight_struggle_tournament, name: "OTSL 2026 - Season 8") }
  let(:other) { create(:twilight_struggle_tournament, name: "RATS Cup 2026") }
  let(:tournaments) { [current, other] }

  it "names the tournament being configured" do
    expect(html).to include("OTSL 2026 - Season 8")
  end

  it "links to the others" do
    expect(html).to include(edit_twilight_struggle_tournament_path(other)).and include("RATS Cup 2026")
  end

  it "does not link to the one already open" do
    expect(html).not_to include(edit_twilight_struggle_tournament_path(current))
  end

  context "when a listed tournament is a bracket" do
    let(:parent) { create(:twilight_struggle_tournament, name: "OTSL 2026") }
    let(:other) { create(:twilight_struggle_tournament, name: "Round of 16", parent:) }

    it "says which league it belongs to" do
      expect(html).to include("Part of OTSL 2026")
    end
  end

  context "when there is nowhere else to go" do
    let(:tournaments) { [current] }

    it "falls back to a plain badge rather than an empty dropdown" do
      expect(html).to include("OTSL 2026 - Season 8")
      expect(html).not_to include("<details")
    end
  end
end
