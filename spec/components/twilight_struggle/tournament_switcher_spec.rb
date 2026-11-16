# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::TwilightStruggle::TournamentSwitcher do
  include Rails.application.routes.url_helpers

  include_context "component view context"

  subject(:html) { described_class.new(current:, destinations:).render_in(view_context) }

  let(:server_configuration) { create(:server_configuration) }
  let(:current_tournament) { create(:twilight_struggle_tournament, name: "OTSL 2026 - Season 8") }
  let(:current) { create(:twilight_struggle_destination, tournament: current_tournament, server_configuration:) }
  let(:other_tournament) { create(:twilight_struggle_tournament, name: "RATS Cup 2026") }
  let(:other) { create(:twilight_struggle_destination, tournament: other_tournament, server_configuration:) }
  let(:destinations) { [current, other] }

  it "leaves the tournament's name to the page heading" do
    expect(html).to include("Switch tournament")
    expect(html).not_to include("OTSL 2026 - Season 8")
  end

  it "links to the others" do
    expect(html).to include(edit_server_twilight_struggle_destination_path(server_configuration.discord_id, other_tournament)).and include("RATS Cup 2026")
  end

  it "does not link to the one already open" do
    expect(html).not_to include(edit_server_twilight_struggle_destination_path(server_configuration.discord_id, current_tournament))
  end

  context "when a listed tournament is a bracket" do
    let(:parent) { create(:twilight_struggle_tournament, name: "OTSL 2026") }
    let(:other_tournament) { create(:twilight_struggle_tournament, name: "Round of 16", parent:) }

    it "says which league it belongs to" do
      expect(html).to include("Part of OTSL 2026")
    end
  end

  context "when there is nowhere else to go" do
    let(:destinations) { [current] }

    it "renders nothing" do
      expect(html).to be_empty
    end
  end
end
